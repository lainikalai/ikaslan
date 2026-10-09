/*
 * IKA Mail Explorer - control add-in para Business Central.
 * Vista tipo Outlook: árbol de carpetas | emails de la carpeta | panel de lectura (ocultable).
 * Solo pinta lo que envía AL y avisa de lo que hace el usuario con eventos.
 * Todo el texto se inserta con textContent; el cuerpo del email va en un iframe aislado sin scripts.
 */
(function () {
    'use strict';

    var BUSY_TIMEOUT_MS = 30000;
    var SELECT_DELAY_MS = 250;
    var NARROW_WIDTH = 760;
    var STORAGE_KEY = 'ika-mail-explorer-collapsed';

    var state = {
        mailboxes: { current: '', items: [] },
        folders: { selected: '', items: [] },
        messages: { folderId: '', title: '', selected: 0, truncated: false, items: [] },
        detail: null,
        readingPane: true,
        search: '',
        collapsed: loadCollapsed(),
        foldersOpen: false,   // panel de carpetas desplegado en pantallas estrechas
        readerOpen: false     // panel de lectura a pantalla completa en pantallas estrechas
    };
    var ui = {};
    var busyTimer = null;
    var statusTimer = null;
    var selectTimer = null;

    // ------------------------------------------------------------------ utilidades

    function invoke(name, args) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(name, args || []);
    }

    function el(tag, className, text) {
        var node = document.createElement(tag);
        if (className) { node.className = className; }
        if (text !== undefined && text !== null) { node.textContent = text; }
        return node;
    }

    // Botón con icono y texto; en pantallas estrechas solo se ve el icono
    function iconButton(className, icon, label, title, onClick) {
        var b = button(className, '', title || label, onClick);
        setIconLabel(b, icon, label);
        return b;
    }

    function setIconLabel(b, icon, label) {
        b.innerHTML = '';
        var iconNode = SVG_ICONS[icon] ? svgIcon(icon) : el('span', 'mx-btn-icon', icon);
        b.appendChild(iconNode);
        b.appendChild(el('span', 'mx-btn-label', ' ' + label));
    }

    // Iconos dibujados (SVG): los emoji dependen de la fuente del navegador y en BC algunos salen casi invisibles
    var SVG_ICONS = {
        trash: 'M3 6h18M8 6V4h8v2M6 6l1 14h10l1-14M10 10v7M14 10v7'
    };

    function svgIcon(name) {
        var ns = 'http://www.w3.org/2000/svg';
        var svg = document.createElementNS(ns, 'svg');
        svg.setAttribute('viewBox', '0 0 24 24');
        svg.setAttribute('width', '14');
        svg.setAttribute('height', '14');
        svg.setAttribute('aria-hidden', 'true');
        svg.setAttribute('class', 'mx-svg');
        var path = document.createElementNS(ns, 'path');
        path.setAttribute('d', SVG_ICONS[name]);
        path.setAttribute('fill', 'none');
        path.setAttribute('stroke', 'currentColor');
        path.setAttribute('stroke-width', '2');
        path.setAttribute('stroke-linecap', 'round');
        path.setAttribute('stroke-linejoin', 'round');
        svg.appendChild(path);
        return svg;
    }

    function button(className, text, title, onClick) {
        var b = el('button', className, text);
        b.type = 'button';
        if (title) { b.title = title; }
        b.addEventListener('click', function (e) {
            e.stopPropagation();
            onClick(e);
        });
        return b;
    }

    function parseJson(text, fallback) {
        if (text && typeof text === 'object') { return text; }
        try { return JSON.parse(text); } catch (e) { return fallback; }
    }

    // Búsqueda sin distinguir mayúsculas ni acentos
    function normalize(text) {
        return String(text || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
    }

    function loadCollapsed() {
        try {
            return JSON.parse(window.localStorage.getItem(STORAGE_KEY) || '{}') || {};
        } catch (e) {
            return {};
        }
    }

    function saveCollapsed() {
        try {
            window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state.collapsed));
        } catch (e) { /* sin almacenamiento local: no se recuerda */ }
    }

    function isNarrow() {
        return ui.root.clientWidth > 0 && ui.root.clientWidth < NARROW_WIDTH;
    }

    function folderIcon(wellKnown) {
        switch (wellKnown) {
            case 'inbox': return '\u{1F4E5}';
            case 'drafts': return '\u{1F4DD}';
            case 'sentitems': return '\u{1F4E4}';
            case 'deleteditems': return '\u{1F5D1}';
            case 'junkemail': return '⚠';
            case 'archive': return '\u{1F5C4}';
            default: return '\u{1F4C1}';
        }
    }

    // ------------------------------------------------------------------ estructura

    function init() {
        ui.root = document.getElementById('controlAddIn');
        ui.root.innerHTML = '';
        ui.root.className = 'mx-root';

        ui.progress = el('div', 'mx-progress');
        ui.root.appendChild(ui.progress);
        ui.root.appendChild(buildToolbar());

        ui.main = el('div', 'mx-main');
        ui.main.appendChild(buildFolderPane());
        ui.main.appendChild(buildListPane());
        ui.main.appendChild(buildReadingPane());
        ui.root.appendChild(ui.main);

        ui.status = el('div', 'mx-status');
        ui.root.appendChild(ui.status);

        if (window.ResizeObserver) {
            new window.ResizeObserver(updateLayout).observe(ui.root);
        } else {
            window.addEventListener('resize', updateLayout);
        }
        updateLayout();
        renderReadingPane();
    }

    function buildToolbar() {
        var bar = el('div', 'mx-toolbar');

        ui.menuButton = button('mx-tool mx-menu', '☰', 'Carpetas', function () {
            state.foldersOpen = !state.foldersOpen;
            updateLayout();
        });
        bar.appendChild(ui.menuButton);

        ui.mailboxSelect = el('select', 'mx-mailbox');
        ui.mailboxSelect.title = 'Cuenta de Outlook 365';
        ui.mailboxSelect.addEventListener('change', function () {
            setBusy(true);
            invoke('MailboxSelected', [ui.mailboxSelect.value]);
        });
        bar.appendChild(ui.mailboxSelect);

        bar.appendChild(iconButton('mx-tool', '⟳', 'Sincronizar', 'Descargar los últimos emails de la carpeta (F5 en la página)', function () {
            setBusy(true);
            invoke('SyncRequested');
        }));

        ui.search = el('input', 'mx-search');
        ui.search.type = 'search';
        ui.search.placeholder = 'Buscar en la carpeta (remitente, asunto, texto)';
        ui.search.addEventListener('input', function () {
            state.search = ui.search.value;
            renderMessages();
        });
        bar.appendChild(ui.search);

        ui.paneToggle = iconButton('mx-tool mx-toggle', '◧', '', 'Mostrar u ocultar el panel de lectura', function () {
            state.readingPane = !state.readingPane;
            state.readerOpen = false;
            updateLayout();
            renderReadingPane();
            renderMessages();
            invoke('ReadingPaneToggled', [state.readingPane]);
        });
        bar.appendChild(ui.paneToggle);
        return bar;
    }

    function buildFolderPane() {
        ui.folderPane = el('nav', 'mx-pane mx-folders');
        var header = el('div', 'mx-pane-header');
        header.appendChild(el('span', 'mx-pane-title', 'Carpetas'));
        header.appendChild(button('mx-icon', '↻', 'Volver a leer las carpetas de Outlook', function () {
            setBusy(true);
            invoke('RefreshFoldersRequested');
        }));
        ui.folderPane.appendChild(header);
        ui.folderTree = el('div', 'mx-tree');
        ui.folderTree.setAttribute('role', 'tree');
        ui.folderPane.appendChild(ui.folderTree);
        return ui.folderPane;
    }

    function buildListPane() {
        ui.listPane = el('section', 'mx-pane mx-list');
        var header = el('div', 'mx-pane-header');
        ui.listTitle = el('span', 'mx-pane-title', '');
        ui.listCount = el('span', 'mx-count', '');
        header.appendChild(ui.listTitle);
        header.appendChild(ui.listCount);
        ui.listPane.appendChild(header);

        // Acciones del email seleccionado cuando el panel de lectura está oculto
        ui.listActions = el('div', 'mx-list-actions');
        ui.listPane.appendChild(ui.listActions);

        ui.list = el('div', 'mx-messages');
        ui.list.tabIndex = 0;
        ui.list.setAttribute('role', 'listbox');
        ui.list.addEventListener('keydown', onListKey);
        ui.listPane.appendChild(ui.list);
        return ui.listPane;
    }

    function buildReadingPane() {
        ui.readingPane = el('section', 'mx-pane mx-reading');
        ui.readerBack = button('mx-tool mx-back', '← Volver a la lista', '', function () {
            state.readerOpen = false;
            updateLayout();
        });
        ui.readingPane.appendChild(ui.readerBack);
        ui.readerEmpty = el('div', 'mx-empty', 'Seleccione un email para leerlo');
        ui.readingPane.appendChild(ui.readerEmpty);

        ui.reader = el('div', 'mx-reader');
        ui.readerHeader = el('div', 'mx-reader-header');
        ui.reader.appendChild(ui.readerHeader);
        ui.readerActions = el('div', 'mx-reader-actions');
        ui.reader.appendChild(ui.readerActions);
        ui.readerAttachments = el('div', 'mx-attachments');
        ui.reader.appendChild(ui.readerAttachments);

        ui.bodyFrame = createBodyFrame('');
        ui.reader.appendChild(ui.bodyFrame);
        ui.readingPane.appendChild(ui.reader);
        return ui.readingPane;
    }

    // Iframe aislado para el cuerpo del email. Sin allow-scripts ni allow-same-origin: el HTML del email
    // no puede ejecutar código.
    function createBodyFrame(html) {
        var frame = document.createElement('iframe');
        frame.className = 'mx-body';
        frame.setAttribute('sandbox', 'allow-popups allow-popups-to-escape-sandbox');
        frame.setAttribute('referrerpolicy', 'no-referrer');
        frame.title = 'Cuerpo del email';
        frame.srcdoc = html || '';
        return frame;
    }

    // Cambiar srcdoc de un iframe ya insertado añade una entrada al historial del navegador, y la flecha
    // "Atrás" de BC iría recorriendo los emails en lugar de cerrar la página. Un iframe nuevo, con el
    // contenido puesto antes de insertarlo, no añade entradas.
    function setBody(html) {
        var frame = createBodyFrame(html);
        ui.bodyFrame.parentNode.replaceChild(frame, ui.bodyFrame);
        ui.bodyFrame = frame;
    }

    function updateLayout() {
        var narrow = isNarrow();
        ui.root.classList.toggle('mx-narrow', narrow);
        ui.root.classList.toggle('mx-no-reading', !state.readingPane);
        ui.root.classList.toggle('mx-folders-open', narrow && state.foldersOpen);
        ui.root.classList.toggle('mx-reader-open', narrow && state.readingPane && state.readerOpen);
        setIconLabel(ui.paneToggle, '◧', state.readingPane ? 'Ocultar lectura' : 'Mostrar lectura');
        ui.paneToggle.classList.toggle('mx-active', state.readingPane);
    }

    // ------------------------------------------------------------------ cuentas

    function renderMailboxes() {
        ui.mailboxSelect.innerHTML = '';
        state.mailboxes.items.forEach(function (m) {
            var option = el('option', null, m.label);
            option.value = m.code;
            ui.mailboxSelect.appendChild(option);
        });
        ui.mailboxSelect.value = state.mailboxes.current;
        ui.mailboxSelect.style.display = state.mailboxes.items.length > 1 ? '' : 'none';
    }

    // ------------------------------------------------------------------ carpetas

    function renderFolders() {
        var items = state.folders.items;
        ui.folderTree.innerHTML = '';
        var hiddenBelowLevel = -1; // nivel de la carpeta plegada cuyas subcarpetas se ocultan
        items.forEach(function (f) {
            if (hiddenBelowLevel >= 0) {
                if (f.level > hiddenBelowLevel) { return; }
                hiddenBelowLevel = -1;
            }
            var collapsed = f.children && state.collapsed[f.id];
            if (collapsed) { hiddenBelowLevel = f.level; }
            ui.folderTree.appendChild(renderFolder(f, collapsed));
        });
        if (!items.length) {
            ui.folderTree.appendChild(el('div', 'mx-empty-small', 'Sin carpetas'));
        }
    }

    function renderFolder(f, collapsed) {
        var row = el('div', 'mx-folder' + (f.id === state.folders.selected ? ' mx-selected' : '') + (f.unread ? ' mx-unread' : ''));
        row.setAttribute('role', 'treeitem');
        row.style.paddingLeft = (6 + f.level * 14) + 'px';
        row.title = f.path;

        var caret = el('span', 'mx-caret', f.children ? (collapsed ? '▸' : '▾') : '');
        if (f.children) {
            caret.addEventListener('click', function (e) {
                e.stopPropagation();
                if (state.collapsed[f.id]) { delete state.collapsed[f.id]; } else { state.collapsed[f.id] = true; }
                saveCollapsed();
                renderFolders();
            });
        }
        row.appendChild(caret);
        row.appendChild(el('span', 'mx-folder-icon', folderIcon(f.wellKnown)));
        row.appendChild(el('span', 'mx-folder-name', f.name));
        if (f.unread) { row.appendChild(el('span', 'mx-badge', String(f.unread))); }

        row.addEventListener('click', function () {
            state.foldersOpen = false;
            updateLayout();
            if (f.id === state.folders.selected) { return; }
            state.folders.selected = f.id;
            renderFolders();
            setBusy(true);
            invoke('FolderSelected', [f.id]);
        });
        return row;
    }

    function adjustFolderUnread(folderId, delta) {
        state.folders.items.forEach(function (f) {
            if (f.id === folderId) { f.unread = Math.max(0, (f.unread || 0) + delta); }
        });
        renderFolders();
    }

    // ------------------------------------------------------------------ lista de emails

    function visibleMessages() {
        var term = normalize(state.search.trim());
        if (!term) { return state.messages.items; }
        return state.messages.items.filter(function (m) {
            return normalize(m.from + ' ' + m.fromAddress + ' ' + m.subject + ' ' + m.preview).indexOf(term) >= 0;
        });
    }

    function renderMessages() {
        var list = visibleMessages();
        var all = state.messages.items;
        ui.listTitle.textContent = state.messages.title || '';
        ui.listCount.textContent = state.search.trim()
            ? list.length + ' de ' + all.length
            : (all.length ? String(all.length) : '');

        var scrollTop = ui.list.scrollTop;
        ui.list.innerHTML = '';
        if (!all.length) {
            ui.list.appendChild(el('div', 'mx-empty', 'No hay emails descargados en esta carpeta. Pulse Sincronizar.'));
        } else if (!list.length) {
            ui.list.appendChild(el('div', 'mx-empty', 'Ningún email coincide con la búsqueda.'));
        }
        list.forEach(function (m) { ui.list.appendChild(renderMessageRow(m)); });

        if (all.length) {
            var footer = el('div', 'mx-list-footer');
            if (state.messages.truncated) {
                footer.appendChild(el('div', 'mx-note', 'Se muestran los 500 más recientes.'));
            }
            footer.appendChild(button('mx-link', 'Cargar anteriores', 'Descargar de Outlook emails más antiguos de esta carpeta', function () {
                setBusy(true);
                invoke('LoadOlderRequested');
            }));
            ui.list.appendChild(footer);
        }
        ui.list.scrollTop = scrollTop;
        renderListActions();
    }

    function renderMessageRow(m) {
        var row = el('div', 'mx-message' + (m.read ? '' : ' mx-unread') + (m.id === state.messages.selected ? ' mx-selected' : ''));
        row.setAttribute('role', 'option');
        row.setAttribute('data-id', String(m.id));

        var line1 = el('div', 'mx-line');
        line1.appendChild(el('span', 'mx-from', m.from || m.fromAddress || '(sin remitente)'));
        var icons = el('span', 'mx-icons');
        if (m.important) { icons.appendChild(el('span', 'mx-important', '!')); }
        if (m.attachments) { icons.appendChild(el('span', null, '\u{1F4CE}')); }
        if (m.linked) {
            var linked = el('span', null, '\u{1F517}');
            linked.title = 'Adjuntado a entidades de BC';
            icons.appendChild(linked);
        }
        line1.appendChild(icons);
        var date = el('span', 'mx-date', m.date);
        date.title = m.dateFull;
        line1.appendChild(date);
        row.appendChild(line1);

        row.appendChild(el('div', 'mx-subject', m.subject || '(sin asunto)'));
        if (m.preview) { row.appendChild(el('div', 'mx-preview', m.preview)); }

        row.addEventListener('click', function () { selectMessage(m.id, true); });
        row.addEventListener('dblclick', function () { invoke('MessageOpened', [m.id]); });
        return row;
    }

    function selectMessage(id, immediate) {
        if (!id) { return; }
        var changed = id !== state.messages.selected;
        state.messages.selected = id;
        Array.prototype.forEach.call(ui.list.querySelectorAll('.mx-message'), function (row) {
            var selected = row.getAttribute('data-id') === String(id);
            row.classList.toggle('mx-selected', selected);
            if (selected && !immediate) { row.scrollIntoView({ block: 'nearest' }); }
        });
        renderListActions();
        if (state.readingPane) {
            state.readerOpen = true;
            updateLayout();
            if (changed || !state.detail || state.detail.id !== id) { showLoadingDetail(); }
        }
        if (!changed && state.detail && state.detail.id === id) { return; }
        // Con las flechas se espera un poco para no cargar cada email por el que se pasa
        if (selectTimer) { clearTimeout(selectTimer); }
        selectTimer = setTimeout(function () {
            selectTimer = null;
            invoke('MessageSelected', [id]);
        }, immediate ? 0 : SELECT_DELAY_MS);
    }

    function onListKey(e) {
        var list = visibleMessages();
        if (!list.length) { return; }
        var index = -1;
        list.forEach(function (m, i) { if (m.id === state.messages.selected) { index = i; } });
        if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
            e.preventDefault();
            index = e.key === 'ArrowDown' ? Math.min(list.length - 1, index + 1) : Math.max(0, index - 1);
            selectMessage(list[index].id, false);
        } else if (e.key === 'Enter' && index >= 0) {
            e.preventDefault();
            invoke('MessageOpened', [list[index].id]);
        } else if (e.key === 'Delete' && index >= 0) {
            e.preventDefault();
            requestDelete(list[index].id);
        }
    }

    // El email que queda seleccionado después de eliminar: el siguiente de la lista o, si era el último, el anterior
    function requestDelete(id) {
        var list = visibleMessages();
        var next = 0;
        list.forEach(function (m, i) {
            if (m.id === id) {
                if (i + 1 < list.length) { next = list[i + 1].id; } else if (i > 0) { next = list[i - 1].id; }
            }
        });
        setBusy(true);
        invoke('DeleteRequested', [id, next]);
    }

    function selectedMessage() {
        var found = null;
        state.messages.items.forEach(function (m) { if (m.id === state.messages.selected) { found = m; } });
        return found;
    }

    // Con el panel de lectura oculto, las acciones del email seleccionado van encima de la lista
    function renderListActions() {
        ui.listActions.innerHTML = '';
        var m = selectedMessage();
        if (state.readingPane || !m) { return; }
        appendMessageActions(ui.listActions, m.id, m.read, true);
    }

    function appendMessageActions(container, id, isRead, includeOpen) {
        if (includeOpen) {
            container.appendChild(button('mx-action mx-primary', 'Abrir', 'Abrir la ficha del email (también con doble clic o Intro)', function () {
                invoke('MessageOpened', [id]);
            }));
        }
        container.appendChild(button('mx-action', '↩ Responder', 'Responder al remitente', function () {
            invoke('ComposeRequested', [id, 'reply']);
        }));
        container.appendChild(button('mx-action', '↩↩ A todos', 'Responder a todos', function () {
            invoke('ComposeRequested', [id, 'replyAll']);
        }));
        container.appendChild(button('mx-action', '↪ Reenviar', 'Reenviar', function () {
            invoke('ComposeRequested', [id, 'forward']);
        }));
        container.appendChild(button('mx-action', 'Mover…', 'Mover a otra carpeta de Outlook', function () {
            invoke('MoveRequested', [id]);
        }));
        container.appendChild(iconButton('mx-action mx-danger', 'trash', 'Eliminar', 'Mover a Elementos eliminados (Supr). En Elementos eliminados, borrar definitivamente.', function () {
            requestDelete(id);
        }));
        container.appendChild(button('mx-action', isRead ? 'Marcar no leído' : 'Marcar leído', '', function () {
            invoke('ToggleReadRequested', [id]);
        }));
        if (!includeOpen) {
            container.appendChild(button('mx-action', '\u{1F4CE} Adjuntar a BC…', 'Abrir la ficha del email para arrastrar el email o sus adjuntos a clientes, proveedores...', function () {
                invoke('MessageOpened', [id]);
            }));
        }
        var more = el('span', 'mx-more');
        more.appendChild(button('mx-action', 'Outlook', 'Abrir en Outlook Web', function () {
            invoke('OpenInOutlookRequested', [id]);
        }));
        more.appendChild(button('mx-action', '.eml', 'Descargar el email completo (.eml)', function () {
            invoke('DownloadEmlRequested', [id]);
        }));
        container.appendChild(more);
    }

    // ------------------------------------------------------------------ panel de lectura

    function showLoadingDetail() {
        ui.readerEmpty.style.display = 'none';
        ui.reader.style.display = '';
        ui.reader.classList.add('mx-loading');
    }

    function renderReadingPane() {
        var d = state.detail;
        ui.reader.classList.remove('mx-loading');
        if (!d) {
            ui.readerEmpty.style.display = '';
            ui.reader.style.display = 'none';
            setBody('');
            return;
        }
        ui.readerEmpty.style.display = 'none';
        ui.reader.style.display = '';

        ui.readerHeader.innerHTML = '';
        ui.readerHeader.appendChild(el('div', 'mx-reader-subject', d.subject || '(sin asunto)'));
        var from = el('div', 'mx-reader-from');
        from.appendChild(el('strong', null, d.from));
        if (d.fromAddress && d.fromAddress !== d.from) {
            from.appendChild(el('span', 'mx-muted', ' <' + d.fromAddress + '>'));
        }
        ui.readerHeader.appendChild(from);
        appendHeaderLine('Para', d.to);
        appendHeaderLine('CC', d.cc);
        var meta = d.date + (d.folder ? ' · ' + d.folder : '') + (d.links ? ' · \u{1F517} ' + d.links + ' vínculo(s) con BC' : '');
        ui.readerHeader.appendChild(el('div', 'mx-reader-meta', meta));

        ui.readerActions.innerHTML = '';
        appendMessageActions(ui.readerActions, d.id, d.read, false);

        ui.readerAttachments.innerHTML = '';
        (d.attachments || []).forEach(function (a) {
            var chip = button('mx-chip', (a.reference ? '\u{1F517} ' : '\u{1F4CE} ') + a.name + (a.size ? ' (' + a.size + ')' : ''),
                a.reference ? 'Enlace a OneDrive/SharePoint: ábralo desde Outlook' : 'Descargar', function () {
                    invoke('DownloadAttachmentRequested', [d.id, a.line]);
                });
            ui.readerAttachments.appendChild(chip);
        });
        ui.readerAttachments.style.display = (d.attachments || []).length ? '' : 'none';
    }

    function appendHeaderLine(label, value) {
        if (!value) { return; }
        var line = el('div', 'mx-reader-line');
        line.appendChild(el('span', 'mx-muted', label + ': '));
        line.appendChild(el('span', null, value));
        ui.readerHeader.appendChild(line);
    }

    // ------------------------------------------------------------------ estado

    function setBusy(isBusy) {
        ui.root.classList.toggle('mx-busy', !!isBusy);
        if (busyTimer) { clearTimeout(busyTimer); busyTimer = null; }
        // Si AL devuelve un error no llega SetBusy(false)
        if (isBusy) { busyTimer = setTimeout(function () { setBusy(false); }, BUSY_TIMEOUT_MS); }
    }

    function showStatus(text, isError) {
        ui.status.textContent = text || '';
        ui.status.className = 'mx-status' + (text ? ' mx-status-visible' : '') + (isError ? ' mx-status-error' : '');
        if (statusTimer) { clearTimeout(statusTimer); }
        if (text && !isError) {
            statusTimer = setTimeout(function () { showStatus('', false); }, 5000);
        }
    }

    // ------------------------------------------------------------------ API para AL

    window.IkaMailExplorer = { init: init };

    window.SetMailboxes = function (dataJson) {
        state.mailboxes = parseJson(dataJson, { current: '', items: [] });
        renderMailboxes();
    };

    window.SetFolders = function (dataJson) {
        state.folders = parseJson(dataJson, { selected: '', items: [] });
        renderFolders();
    };

    window.SetMessages = function (dataJson) {
        var data = parseJson(dataJson, { items: [] });
        var folderChanged = data.folderId !== state.messages.folderId;
        state.messages = data;
        state.messages.items = data.items || [];
        if (folderChanged) {
            state.search = '';
            ui.search.value = '';
            state.readerOpen = false;
            updateLayout();
        }
        renderMessages();
        if (folderChanged) { ui.list.scrollTop = 0; }
        setBusy(false);
    };

    window.UpdateMessage = function (itemJson) {
        var item = parseJson(itemJson, null);
        if (!item) { return; }
        state.messages.items.forEach(function (m, i) {
            if (m.id === item.id) {
                if (m.read !== item.read) { adjustFolderUnread(state.messages.folderId, item.read ? -1 : 1); }
                state.messages.items[i] = item;
            }
        });
        if (state.detail && state.detail.id === item.id) {
            state.detail.read = item.read;
            renderReadingPane();
        }
        renderMessages();
    };

    window.SetMessage = function (detailJson) {
        state.detail = detailJson ? parseJson(detailJson, null) : null;
        if (!state.detail) { setBody(''); }
        renderReadingPane();
        setBusy(false);
    };

    window.SetBody = function (html) {
        setBody(html);
    };

    window.SetReadingPane = function (visible) {
        state.readingPane = !!visible;
        updateLayout();
        renderReadingPane();
        renderListActions();
    };

    window.ShowStatus = function (text, isError) {
        showStatus(text, isError);
        if (isError) { setBusy(false); }
    };

    window.SetBusy = function (isBusy) {
        setBusy(isBusy);
    };
})();

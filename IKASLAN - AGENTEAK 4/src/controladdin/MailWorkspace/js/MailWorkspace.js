/*
 * IKA Mail Workspace - control add-in para Business Central.
 * Izquierda: cuerpo del email (iframe aislado, sin scripts) y elementos arrastrables
 * (email completo .eml y adjuntos). Derecha: zonas de destino (entidades de BC).
 * Alternativa sin ratón: seleccionar un elemento y pulsar "Adjuntar aquí" en el destino.
 */
(function () {
    'use strict';

    var ITEM_MIME = 'application/x-ika-mail-item';
    var MAX_EXTERNAL_FILE_BYTES = 10 * 1024 * 1024;

    var state = { items: [], targets: [], selectedItemId: null };
    var root, bodyFrame, itemsList, targetsList, statusBar, statusTimer;

    function invoke(name, args) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(name, args || []);
    }

    function el(tag, className, text) {
        var node = document.createElement(tag);
        if (className) { node.className = className; }
        if (text !== undefined && text !== null) { node.textContent = text; }
        return node;
    }

    function parseJson(text) {
        try { return JSON.parse(text || '[]'); } catch (e) { return []; }
    }

    function iconFor(kind) {
        switch (kind) {
            case 'email': return '✉';      // sobre
            case 'item': return '✉';
            case 'reference': return '\u{1F517}'; // enlace
            default: return '\u{1F4CE}';         // clip
        }
    }

    // ------------------------------------------------------------------ layout

    function buildLayout() {
        root = document.getElementById('controlAddIn');
        root.innerHTML = '';
        root.className = 'ika-root';

        var main = el('div', 'ika-main');

        var left = el('section', 'ika-left');
        bodyFrame = document.createElement('iframe');
        bodyFrame.className = 'ika-body';
        // Sin allow-scripts ni allow-same-origin: el HTML del email no puede ejecutar código.
        bodyFrame.setAttribute('sandbox', 'allow-popups allow-popups-to-escape-sandbox');
        bodyFrame.setAttribute('referrerpolicy', 'no-referrer');
        bodyFrame.title = 'Cuerpo del email';
        left.appendChild(bodyFrame);
        left.appendChild(el('div', 'ika-section-title', 'Email y adjuntos — arrastre a un destino'));
        itemsList = el('div', 'ika-items');
        left.appendChild(itemsList);

        var right = el('section', 'ika-right');
        right.appendChild(el('div', 'ika-section-title', 'Adjuntar a…'));
        targetsList = el('div', 'ika-targets');
        right.appendChild(targetsList);
        right.appendChild(el('div', 'ika-hint',
            'Arrastre el email o un adjunto sobre una entidad. También puede soltar ficheros desde el escritorio. ' +
            'En pantallas táctiles: toque un elemento y después "Adjuntar aquí".'));

        main.appendChild(left);
        main.appendChild(right);
        statusBar = el('div', 'ika-status');
        root.appendChild(main);
        root.appendChild(statusBar);
    }

    // ------------------------------------------------------------------ items

    function renderItems() {
        itemsList.innerHTML = '';
        state.items.forEach(function (item) {
            var chip = el('div', 'ika-item ika-kind-' + item.kind);
            var draggable = item.kind !== 'reference';
            chip.setAttribute('draggable', draggable ? 'true' : 'false');
            chip.setAttribute('tabindex', '0');
            chip.title = draggable ? 'Arrastre a un destino. Doble clic para descargar.' :
                'Enlace a OneDrive/SharePoint: ábralo desde Outlook.';
            if (state.selectedItemId === item.id) { chip.classList.add('ika-selected'); }

            chip.appendChild(el('span', 'ika-icon', iconFor(item.kind)));
            var text = el('span', 'ika-item-text');
            text.appendChild(el('span', 'ika-item-name', item.name));
            if (item.size) { text.appendChild(el('span', 'ika-item-size', item.size)); }
            if (item.links && item.links.length) {
                text.appendChild(el('span', 'ika-item-links', '✓ ' + item.links.join(', ')));
            }
            chip.appendChild(text);

            if (draggable) {
                var download = el('button', 'ika-btn ika-btn-icon', '⬇');
                download.title = 'Descargar';
                download.addEventListener('click', function (e) {
                    e.stopPropagation();
                    invoke('DownloadRequested', [item.id]);
                });
                chip.appendChild(download);

                chip.addEventListener('dragstart', function (e) {
                    e.dataTransfer.setData(ITEM_MIME, item.id);
                    e.dataTransfer.setData('text/plain', item.name);
                    e.dataTransfer.effectAllowed = 'copy';
                    chip.classList.add('ika-dragging');
                    root.classList.add('ika-drag-active');
                });
                chip.addEventListener('dragend', function () {
                    chip.classList.remove('ika-dragging');
                    root.classList.remove('ika-drag-active');
                });
                chip.addEventListener('click', function () {
                    state.selectedItemId = state.selectedItemId === item.id ? null : item.id;
                    renderItems();
                    renderTargets();
                });
                chip.addEventListener('keydown', function (e) {
                    if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); chip.click(); }
                });
                chip.addEventListener('dblclick', function () { invoke('DownloadRequested', [item.id]); });
            }
            itemsList.appendChild(chip);
        });
    }

    // ------------------------------------------------------------------ targets

    function isAcceptedDrag(e) {
        var types = Array.prototype.slice.call(e.dataTransfer.types || []);
        return types.indexOf(ITEM_MIME) >= 0 || types.indexOf('Files') >= 0;
    }

    function renderTargets() {
        targetsList.innerHTML = '';
        if (!state.targets.length) {
            targetsList.appendChild(el('div', 'ika-empty',
                'No hay destinos. Elija un tipo y nº de entidad en "Destino" o fije entidades para tenerlas siempre a mano.'));
            return;
        }
        state.targets.forEach(function (target) {
            var card = el('div', 'ika-target ika-target-' + target.kind);

            var head = el('div', 'ika-target-head');
            head.appendChild(el('span', 'ika-badge', target.kindCaption));
            var pin = el('button', 'ika-btn ika-btn-icon' + (target.pinned ? ' ika-pinned' : ''), '\u{1F4CC}');
            pin.title = target.pinned ? 'Quitar de fijados' : 'Fijar este destino';
            pin.addEventListener('click', function () { invoke('PinToggled', [target.id]); });
            head.appendChild(pin);
            var open = el('button', 'ika-btn ika-btn-icon', '↗');
            open.title = 'Abrir ficha';
            open.addEventListener('click', function () { invoke('OpenTargetRequested', [target.id]); });
            head.appendChild(open);
            card.appendChild(head);

            card.appendChild(el('div', 'ika-target-type', target.type + ' ' + target.no));
            card.appendChild(el('div', 'ika-target-name', target.name || ''));

            if (state.selectedItemId) {
                var attach = el('button', 'ika-btn ika-btn-primary', 'Adjuntar aquí');
                attach.addEventListener('click', function () {
                    invoke('ItemDropped', [state.selectedItemId, target.id]);
                    state.selectedItemId = null;
                    renderItems();
                    renderTargets();
                });
                card.appendChild(attach);
            } else {
                card.appendChild(el('div', 'ika-drop-hint', 'Suelte aquí'));
            }

            card.addEventListener('dragenter', function (e) {
                if (isAcceptedDrag(e)) { e.preventDefault(); card.classList.add('ika-over'); }
            });
            card.addEventListener('dragover', function (e) {
                if (isAcceptedDrag(e)) {
                    e.preventDefault();
                    e.dataTransfer.dropEffect = 'copy';
                    card.classList.add('ika-over');
                }
            });
            card.addEventListener('dragleave', function (e) {
                if (!card.contains(e.relatedTarget)) { card.classList.remove('ika-over'); }
            });
            card.addEventListener('drop', function (e) {
                e.preventDefault();
                card.classList.remove('ika-over');
                root.classList.remove('ika-drag-active');
                var itemId = e.dataTransfer.getData(ITEM_MIME);
                if (itemId) {
                    invoke('ItemDropped', [itemId, target.id]);
                    return;
                }
                if (e.dataTransfer.files && e.dataTransfer.files.length) {
                    Array.prototype.forEach.call(e.dataTransfer.files, function (file) {
                        sendExternalFile(file, target.id);
                    });
                }
            });

            targetsList.appendChild(card);
        });
    }

    function sendExternalFile(file, targetId) {
        if (file.size > MAX_EXTERNAL_FILE_BYTES) {
            showStatus('El fichero ' + file.name + ' supera 10 MB.', true);
            return;
        }
        var reader = new FileReader();
        reader.onload = function () {
            var dataUrl = String(reader.result || '');
            var base64 = dataUrl.substring(dataUrl.indexOf(',') + 1);
            invoke('FileDropped', [targetId, file.name, base64]);
        };
        reader.onerror = function () { showStatus('No se pudo leer el fichero ' + file.name, true); };
        reader.readAsDataURL(file);
    }

    // ------------------------------------------------------------------ status

    function showStatus(text, isError) {
        statusBar.textContent = text || '';
        statusBar.className = 'ika-status' + (text ? ' ika-status-visible' : '') + (isError ? ' ika-status-error' : '');
        if (statusTimer) { clearTimeout(statusTimer); }
        if (text && !isError) {
            statusTimer = setTimeout(function () { showStatus('', false); }, 6000);
        }
    }

    // ------------------------------------------------------------------ API para AL

    window.IkaMail = { init: buildLayout };

    window.SetBody = function (html) {
        bodyFrame.srcdoc = html || '';
    };

    window.SetItems = function (itemsJson) {
        state.items = parseJson(itemsJson);
        if (state.selectedItemId && !state.items.some(function (i) { return i.id === state.selectedItemId; })) {
            state.selectedItemId = null;
        }
        renderItems();
    };

    window.SetTargets = function (targetsJson) {
        state.targets = parseJson(targetsJson);
        renderTargets();
    };

    window.ShowStatus = function (text, isError) {
        showStatus(text, isError);
    };

    window.SetBusy = function (isBusy) {
        root.classList.toggle('ika-busy', !!isBusy);
    };
})();

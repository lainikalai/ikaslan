// Chat de WhatsApp para Business Central ("IKA WA Chat").
// Solo pinta lo que envía AL (Render) y avisa de las acciones del usuario con eventos.
// Todo el texto de los mensajes se inserta con textContent: nunca como HTML.
var IkaWaChat = (function () {
    'use strict';

    var POLL_SECONDS = 15;
    var SEND_TIMEOUT_MS = 15000;

    var ui = {};
    var state = {
        conversationId: 0,
        windowOpen: false,
        canAttach: false,
        sending: false,
        sendTimer: null,
        images: {} // EntryNo -> data URL ya descargada
    };

    function invoke(name, args) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(name, args || []);
    }

    function el(tag, className, text) {
        var node = document.createElement(tag);
        if (className) {
            node.className = className;
        }
        if (text !== undefined && text !== null) {
            node.textContent = text;
        }
        return node;
    }

    // Texto con enlaces http(s) clicables, sin interpretar HTML
    function appendText(parent, text) {
        var urlPattern = /(https?:\/\/[^\s<>"]+)/g;
        var last = 0;
        var match;
        while ((match = urlPattern.exec(text)) !== null) {
            if (match.index > last) {
                parent.appendChild(document.createTextNode(text.substring(last, match.index)));
            }
            var link = el('a', null, match[0]);
            link.href = match[0];
            link.target = '_blank';
            link.rel = 'noopener noreferrer';
            parent.appendChild(link);
            last = match.index + match[0].length;
        }
        if (last < text.length) {
            parent.appendChild(document.createTextNode(text.substring(last)));
        }
    }

    function init(root) {
        root.innerHTML = '';
        ui.root = el('div', 'wa-chat');

        ui.header = el('div', 'wa-header');
        ui.title = el('div', 'wa-title');
        ui.windowBadge = el('div', 'wa-window');
        ui.header.appendChild(ui.title);
        ui.header.appendChild(ui.windowBadge);

        ui.messages = el('div', 'wa-messages');
        ui.empty = el('div', 'wa-empty', 'Seleccione una conversación');
        ui.messages.appendChild(ui.empty);

        ui.quickReplies = el('div', 'wa-quick');

        ui.closedBar = el('div', 'wa-closed');
        ui.closedText = el('span', null, 'Han pasado más de 24 h desde el último mensaje del cliente: solo se puede escribir con una plantilla aprobada.');
        ui.templateButton = el('button', 'wa-button', 'Enviar plantilla');
        ui.templateButton.type = 'button';
        ui.templateButton.addEventListener('click', function () {
            invoke('SendTemplate');
        });
        ui.closedBar.appendChild(ui.closedText);
        ui.closedBar.appendChild(ui.templateButton);

        ui.composer = el('div', 'wa-composer');
        ui.attachButton = el('button', 'wa-icon-button', '📎');
        ui.attachButton.type = 'button';
        ui.attachButton.title = 'Enviar un fichero (el texto escrito va como pie)';
        ui.attachButton.addEventListener('click', function () {
            invoke('AttachFile', [ui.input.value]);
        });
        ui.input = el('textarea', 'wa-input');
        ui.input.rows = 1;
        ui.input.placeholder = 'Escriba un mensaje (Intro para enviar, Mayús+Intro para salto de línea)';
        ui.input.addEventListener('keydown', function (e) {
            if (e.key === 'Enter' && !e.shiftKey && !e.isComposing) {
                e.preventDefault();
                send();
            }
        });
        ui.input.addEventListener('input', autoGrow);
        ui.sendButton = el('button', 'wa-send', '➤');
        ui.sendButton.type = 'button';
        ui.sendButton.title = 'Enviar';
        ui.sendButton.addEventListener('click', send);
        ui.composer.appendChild(ui.attachButton);
        ui.composer.appendChild(ui.input);
        ui.composer.appendChild(ui.sendButton);

        ui.root.appendChild(ui.header);
        ui.root.appendChild(ui.messages);
        ui.root.appendChild(ui.quickReplies);
        ui.root.appendChild(ui.closedBar);
        ui.root.appendChild(ui.composer);
        root.appendChild(ui.root);

        setEnabled(false);

        // Mensajes nuevos: BC solo vuelve a pintar si algo ha cambiado
        window.setInterval(function () {
            if (state.conversationId && document.visibilityState === 'visible') {
                invoke('Poll');
            }
        }, POLL_SECONDS * 1000);
    }

    function autoGrow() {
        ui.input.style.height = 'auto';
        ui.input.style.height = Math.min(ui.input.scrollHeight, 140) + 'px';
    }

    function send() {
        var text = ui.input.value;
        if (state.sending || !state.windowOpen || text.trim() === '') {
            return;
        }
        setSending(true);
        invoke('SendText', [text]);
    }

    function setSending(sending) {
        state.sending = sending;
        ui.sendButton.disabled = sending || !state.windowOpen;
        if (state.sendTimer) {
            window.clearTimeout(state.sendTimer);
            state.sendTimer = null;
        }
        // Si BC devuelve un error no llega ClearComposer: se reactiva el botón
        if (sending) {
            state.sendTimer = window.setTimeout(function () {
                setSending(false);
            }, SEND_TIMEOUT_MS);
        }
    }

    function setEnabled(enabled) {
        ui.input.disabled = !enabled;
        ui.sendButton.disabled = !enabled || state.sending;
        ui.attachButton.disabled = !enabled;
    }

    function isNearBottom() {
        return ui.messages.scrollHeight - ui.messages.scrollTop - ui.messages.clientHeight < 60;
    }

    function render(data) {
        if (typeof data === 'string') {
            data = JSON.parse(data);
        }
        var changedConversation = data.conversationId !== state.conversationId;
        var stickToBottom = changedConversation || isNearBottom();

        if (changedConversation) {
            ui.input.value = '';
            autoGrow();
            state.images = {};
            setSending(false);
        }
        state.conversationId = data.conversationId || 0;
        state.windowOpen = !!data.windowOpen;
        state.canAttach = !!data.canAttach;

        ui.title.textContent = data.title || '';
        ui.windowBadge.textContent = data.windowText || '';
        ui.windowBadge.className = 'wa-window ' + (state.windowOpen ? 'open' : 'closed');
        ui.header.style.display = state.conversationId ? '' : 'none';

        renderMessages(data);
        renderQuickReplies(data.quickReplies || []);

        var hasConversation = state.conversationId !== 0;
        ui.closedBar.style.display = hasConversation && !state.windowOpen ? '' : 'none';
        ui.composer.style.display = hasConversation && state.windowOpen ? '' : 'none';
        setEnabled(hasConversation && state.windowOpen);

        if (stickToBottom) {
            ui.messages.scrollTop = ui.messages.scrollHeight;
        }
    }

    function renderMessages(data) {
        var list = data.messages || [];
        ui.messages.innerHTML = '';
        if (!data.conversationId) {
            ui.messages.appendChild(ui.empty);
            return;
        }
        if (data.truncated) {
            ui.messages.appendChild(el('div', 'wa-day', 'Solo se muestran los últimos ' + list.length + ' mensajes'));
        }
        if (list.length === 0) {
            ui.messages.appendChild(el('div', 'wa-day', 'Sin mensajes'));
        }
        var lastDay = '';
        list.forEach(function (m) {
            if (m.day !== lastDay) {
                ui.messages.appendChild(el('div', 'wa-day', m.day));
                lastDay = m.day;
            }
            ui.messages.appendChild(renderMessage(m));
        });
    }

    function renderMessage(m) {
        var row = el('div', 'wa-row ' + m.dir);
        var bubble = el('div', 'wa-bubble ' + m.dir + (m.status === 'failed' ? ' failed' : ''));

        if (m.template) {
            bubble.appendChild(el('div', 'wa-tag', 'Plantilla: ' + m.template));
        }
        if (m.hasMedia) {
            bubble.appendChild(renderMedia(m));
        }
        if (m.text) {
            var text = el('div', 'wa-text');
            appendText(text, m.text);
            bubble.appendChild(text);
        }
        if (m.error) {
            bubble.appendChild(el('div', 'wa-error', m.error));
        }

        var meta = el('div', 'wa-meta');
        if (m.sentBy) {
            meta.appendChild(el('span', 'wa-by', m.sentBy));
        }
        meta.appendChild(el('span', null, m.time));
        if (m.dir === 'out') {
            meta.appendChild(renderTicks(m.status));
        }
        bubble.appendChild(meta);
        row.appendChild(bubble);
        return row;
    }

    function renderTicks(status) {
        var ticks = { sent: '✓', delivered: '✓✓', read: '✓✓', failed: '⚠' };
        var titles = { sent: 'Enviado', delivered: 'Entregado', read: 'Leído', failed: 'Error' };
        var span = el('span', 'wa-ticks ' + status, ticks[status] || '');
        span.title = titles[status] || '';
        return span;
    }

    function renderMedia(m) {
        var box = el('div', 'wa-media');
        if (m.isImage && state.images[m.id]) {
            var img = el('img', 'wa-image');
            img.src = state.images[m.id];
            img.alt = m.fileName || '';
            img.title = 'Descargar';
            img.addEventListener('click', function () {
                invoke('DownloadFile', [m.id]);
            });
            box.appendChild(img);
        } else if (m.isImage) {
            var show = el('button', 'wa-file', '🖼 Ver imagen');
            show.type = 'button';
            show.setAttribute('data-image-entry', String(m.id));
            show.addEventListener('click', function () {
                show.disabled = true;
                show.textContent = 'Cargando…';
                invoke('RequestImage', [m.id]);
                // Si BC devuelve un error (p.ej. imagen demasiado grande) no llega ShowImage
                window.setTimeout(function () {
                    if (show.parentNode && show.disabled) {
                        show.disabled = false;
                        show.textContent = '🖼 Ver imagen';
                    }
                }, SEND_TIMEOUT_MS);
            });
            box.appendChild(show);
        } else {
            var file = el('button', 'wa-file', mediaIcon(m.kind) + ' ' + (m.fileName || 'Fichero'));
            file.type = 'button';
            file.title = 'Descargar';
            file.addEventListener('click', function () {
                invoke('DownloadFile', [m.id]);
            });
            box.appendChild(file);
        }
        if (m.dir === 'in' && state.canAttach) {
            var attach = el('button', 'wa-link', m.attached ? '✔ Adjuntado a la ficha' : '📎 Adjuntar a la ficha');
            attach.type = 'button';
            attach.disabled = !!m.attached;
            attach.addEventListener('click', function () {
                attach.disabled = true;
                invoke('AttachToEntity', [m.id]);
            });
            box.appendChild(attach);
        }
        return box;
    }

    function mediaIcon(kind) {
        switch (kind) {
            case 'audio':
                return '🎤';
            case 'video':
                return '🎬';
            default:
                return '📄';
        }
    }

    function renderQuickReplies(replies) {
        ui.quickReplies.innerHTML = '';
        ui.quickReplies.style.display = replies.length && state.windowOpen ? '' : 'none';
        replies.forEach(function (r) {
            var chip = el('button', 'wa-chip', r.label);
            chip.type = 'button';
            chip.title = r.text;
            chip.addEventListener('click', function () {
                var current = ui.input.value;
                ui.input.value = current.trim() === '' ? r.text : current.replace(/\s+$/, '') + ' ' + r.text;
                autoGrow();
                ui.input.focus();
            });
            ui.quickReplies.appendChild(chip);
        });
    }

    function showImage(entryNo, dataUrl) {
        state.images[entryNo] = dataUrl;
        var atBottom = isNearBottom();
        // Basta con sustituir el botón "Ver imagen" de ese mensaje por la imagen
        var button = ui.messages.querySelector('[data-image-entry="' + String(entryNo) + '"]');
        if (button) {
            var img = el('img', 'wa-image');
            img.src = dataUrl;
            img.title = 'Descargar';
            img.addEventListener('click', function () {
                invoke('DownloadFile', [entryNo]);
            });
            button.parentNode.replaceChild(img, button);
        }
        if (atBottom) {
            ui.messages.scrollTop = ui.messages.scrollHeight;
        }
    }

    function clearComposer() {
        ui.input.value = '';
        autoGrow();
        setSending(false);
        ui.input.focus();
    }

    return {
        init: init,
        render: render,
        showImage: showImage,
        clearComposer: clearComposer
    };
})();

// Procedimientos del control add-in (llamados desde AL)
function Render(data) {
    IkaWaChat.render(data);
}

function ShowImage(entryNo, dataUrl) {
    IkaWaChat.showImage(entryNo, dataUrl);
}

function ClearComposer() {
    IkaWaChat.clearComposer();
}

/*
 * Puente WhatsApp (Meta Cloud API) -> Business Central.
 *
 * GET  /api/whatsapp  : verificación del webhook (Meta envía hub.challenge una sola vez).
 * POST /api/whatsapp  : notificaciones de Meta (mensajes recibidos y cambios de estado).
 *   1. Comprueba la firma X-Hub-Signature-256 con el App Secret (rechaza lo que no venga de Meta).
 *   2. Convierte cada mensaje/estado en un evento plano.
 *   3. Lo inserta en BC: POST .../api/ikaslan/whatsapp/v1.0/companies({id})/inboundEvents
 * Si BC falla se devuelve 500 y Meta reintenta; BC descarta duplicados por el id del mensaje (wamid).
 */
const { app } = require('@azure/functions');
const crypto = require('crypto');

const TEXT_PART_LENGTH = 2048;

app.http('whatsappWebhook', {
    methods: ['GET', 'POST'],
    authLevel: 'anonymous', // la seguridad la da la firma de Meta (POST) y el verify token (GET)
    route: 'whatsapp',
    handler: async (request, context) => {
        if (request.method === 'GET') {
            return verifySubscription(request);
        }

        const rawBody = await request.text();
        if (!isValidSignature(rawBody, request.headers.get('x-hub-signature-256'))) {
            context.warn('Firma X-Hub-Signature-256 no válida: petición rechazada.');
            return { status: 401 };
        }

        let payload;
        try {
            payload = JSON.parse(rawBody);
        } catch (e) {
            return { status: 400 };
        }

        const events = normalizePayload(payload);
        if (events.length === 0) {
            return { status: 200 };
        }

        try {
            const token = await getBusinessCentralToken();
            for (const event of events) {
                await postToBusinessCentral(token, event);
            }
            context.log(`${events.length} evento(s) enviados a Business Central.`);
            return { status: 200 };
        } catch (err) {
            context.error('Error enviando a Business Central', err);
            return { status: 500 }; // Meta reintentará
        }
    }
});

// --------------------------------------------------------------------------- verificación

function verifySubscription(request) {
    const mode = request.query.get('hub.mode');
    const token = request.query.get('hub.verify_token');
    const challenge = request.query.get('hub.challenge');
    if (mode === 'subscribe' && token && token === process.env.WA_VERIFY_TOKEN) {
        return { status: 200, body: challenge };
    }
    return { status: 403 };
}

function isValidSignature(rawBody, signatureHeader) {
    const appSecret = process.env.WA_APP_SECRET;
    if (!appSecret || !signatureHeader || !signatureHeader.startsWith('sha256=')) {
        return false;
    }
    const expected = 'sha256=' + crypto.createHmac('sha256', appSecret).update(rawBody, 'utf8').digest('hex');
    const a = Buffer.from(expected, 'utf8');
    const b = Buffer.from(signatureHeader, 'utf8');
    return a.length === b.length && crypto.timingSafeEqual(a, b);
}

// --------------------------------------------------------------------------- normalización

/**
 * Convierte el webhook de Meta en eventos planos con los nombres de campo de la página API de BC.
 */
function normalizePayload(payload) {
    const events = [];
    for (const entry of payload.entry || []) {
        for (const change of entry.changes || []) {
            if (change.field !== 'messages' || !change.value) {
                continue;
            }
            const value = change.value;
            const phoneNumberId = (value.metadata && value.metadata.phone_number_id) || '';
            const profileNames = {};
            for (const contact of value.contacts || []) {
                profileNames[contact.wa_id] = (contact.profile && contact.profile.name) || '';
            }

            for (const message of value.messages || []) {
                events.push(messageToEvent(phoneNumberId, profileNames[message.from] || '', message));
            }
            for (const status of value.statuses || []) {
                events.push(statusToEvent(phoneNumberId, status));
            }
        }
    }
    return events;
}

function messageToEvent(phoneNumberId, profileName, message) {
    const content = extractContent(message);
    const text = content.text || '';
    return {
        eventKind: 'Message',
        phoneNumberId: cut(phoneNumberId, 50),
        fromPhone: cut(message.from, 30),
        profileName: cut(profileName, 100),
        waMessageId: cut(message.id, 250),
        contextMessageId: cut(message.context && message.context.id, 250),
        unixTimestamp: Number(message.timestamp) || 0,
        messageType: cut(message.type, 30),
        textPart1: text.substring(0, TEXT_PART_LENGTH),
        textPart2: text.substring(TEXT_PART_LENGTH, TEXT_PART_LENGTH * 2),
        mediaId: cut(content.mediaId, 100),
        mimeType: cut(content.mimeType, 100),
        fileName: cut(content.fileName, 250)
    };
}

function extractContent(message) {
    const type = message.type;
    const media = message[type] || {};
    switch (type) {
        case 'text':
            return { text: message.text && message.text.body };
        case 'image':
        case 'document':
        case 'audio':
        case 'video':
        case 'sticker':
            return {
                text: media.caption || '',
                mediaId: media.id,
                mimeType: media.mime_type,
                fileName: media.filename || ''
            };
        case 'location':
            return {
                text: `Ubicación: ${media.latitude},${media.longitude}` +
                    (media.name ? ` - ${media.name}` : '') + (media.address ? ` (${media.address})` : '')
            };
        case 'contacts':
            return {
                text: 'Contacto compartido: ' + (message.contacts || []).map(c =>
                    ((c.name && c.name.formatted_name) || '') + ' ' +
                    (c.phones || []).map(p => p.phone).join(', ')).join(' | ')
            };
        case 'interactive': {
            const reply = media.button_reply || media.list_reply || {};
            return { text: reply.title || '' };
        }
        case 'button':
            return { text: (message.button && message.button.text) || '' };
        case 'reaction':
            return { text: `${(message.reaction && message.reaction.emoji) || ''} (reacción)` };
        default:
            return { text: `[Mensaje de tipo ${type} no soportado]` };
    }
}

function statusToEvent(phoneNumberId, status) {
    const errorText = (status.errors || [])
        .map(e => `${e.code} ${e.title || ''} ${(e.error_data && e.error_data.details) || ''}`.trim())
        .join('; ');
    return {
        eventKind: 'Status',
        phoneNumberId: cut(phoneNumberId, 50),
        fromPhone: cut(status.recipient_id, 30),
        waMessageId: cut(status.id, 250),
        unixTimestamp: Number(status.timestamp) || 0,
        statusValue: cut(status.status, 30),
        errorText: cut(errorText, 2048)
    };
}

function cut(value, maxLength) {
    return String(value || '').substring(0, maxLength);
}

// --------------------------------------------------------------------------- Business Central

let cachedToken = null;
let cachedTokenExpiry = 0;

async function getBusinessCentralToken() {
    if (cachedToken && Date.now() < cachedTokenExpiry - 60000) {
        return cachedToken;
    }
    const body = new URLSearchParams({
        grant_type: 'client_credentials',
        client_id: process.env.BC_CLIENT_ID,
        client_secret: process.env.BC_CLIENT_SECRET,
        scope: 'https://api.businesscentral.dynamics.com/.default'
    });
    const response = await fetch(`https://login.microsoftonline.com/${process.env.BC_TENANT_ID}/oauth2/v2.0/token`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body
    });
    if (!response.ok) {
        throw new Error(`Token de BC: HTTP ${response.status} ${await response.text()}`);
    }
    const json = await response.json();
    cachedToken = json.access_token;
    cachedTokenExpiry = Date.now() + (json.expires_in || 3600) * 1000;
    return cachedToken;
}

async function postToBusinessCentral(token, event) {
    const base = process.env.BC_API_BASE || 'https://api.businesscentral.dynamics.com/v2.0';
    const url = `${base}/${process.env.BC_TENANT_ID}/${process.env.BC_ENVIRONMENT}` +
        `/api/ikaslan/whatsapp/v1.0/companies(${process.env.BC_COMPANY_ID})/inboundEvents`;
    const response = await fetch(url, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(event)
    });
    if (!response.ok) {
        throw new Error(`BC: HTTP ${response.status} ${await response.text()}`);
    }
}

module.exports = { normalizePayload, isValidSignature, verifySubscription };

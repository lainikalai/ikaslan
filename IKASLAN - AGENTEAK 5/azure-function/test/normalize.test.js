// Prueba local sin Azure: node --test
const test = require('node:test');
const assert = require('node:assert');
const crypto = require('crypto');

// Simula el registro de @azure/functions para poder cargar el módulo sin el runtime
require.cache[require.resolve('@azure/functions')] = { exports: { app: { http: () => {} } } };
const { normalizePayload, isValidSignature } = require('../src/functions/whatsappWebhook');

const samplePayload = {
    object: 'whatsapp_business_account',
    entry: [{
        id: 'WABA_ID',
        changes: [{
            field: 'messages',
            value: {
                messaging_product: 'whatsapp',
                metadata: { display_phone_number: '34944000000', phone_number_id: '1234567890' },
                contacts: [{ profile: { name: 'Ane' }, wa_id: '34600123456' }],
                messages: [
                    { from: '34600123456', id: 'wamid.TEXT', timestamp: '1759651200', type: 'text', text: { body: 'Hola, quiero 20 cajas de la ref. A-100' } },
                    { from: '34600123456', id: 'wamid.DOC', timestamp: '1759651260', type: 'document', document: { id: 'MEDIA1', mime_type: 'application/pdf', filename: 'pedido.pdf', caption: 'Pedido' } }
                ],
                statuses: [
                    { id: 'wamid.OUT', status: 'failed', timestamp: '1759651300', recipient_id: '34600123456', errors: [{ code: 131047, title: 'Re-engagement message' }] }
                ]
            }
        }]
    }]
};

test('normaliza mensajes y estados', () => {
    const events = normalizePayload(samplePayload);
    assert.strictEqual(events.length, 3);
    assert.deepStrictEqual(
        { kind: events[0].eventKind, from: events[0].fromPhone, name: events[0].profileName, text: events[0].textPart1, account: events[0].phoneNumberId },
        { kind: 'Message', from: '34600123456', name: 'Ane', text: 'Hola, quiero 20 cajas de la ref. A-100', account: '1234567890' });
    assert.strictEqual(events[1].mediaId, 'MEDIA1');
    assert.strictEqual(events[1].fileName, 'pedido.pdf');
    assert.strictEqual(events[1].textPart1, 'Pedido');
    assert.strictEqual(events[2].eventKind, 'Status');
    assert.strictEqual(events[2].statusValue, 'failed');
    assert.match(events[2].errorText, /131047/);
});

test('divide textos largos en dos partes de 2048', () => {
    const long = 'x'.repeat(3000);
    const payload = JSON.parse(JSON.stringify(samplePayload));
    payload.entry[0].changes[0].value.messages = [{ from: '1', id: 'w', timestamp: '1', type: 'text', text: { body: long } }];
    payload.entry[0].changes[0].value.statuses = [];
    const [event] = normalizePayload(payload);
    assert.strictEqual(event.textPart1.length, 2048);
    assert.strictEqual(event.textPart2.length, 952);
});

test('valida la firma de Meta', () => {
    process.env.WA_APP_SECRET = 'secreto';
    const body = JSON.stringify(samplePayload);
    const signature = 'sha256=' + crypto.createHmac('sha256', 'secreto').update(body, 'utf8').digest('hex');
    assert.strictEqual(isValidSignature(body, signature), true);
    assert.strictEqual(isValidSignature(body + ' ', signature), false);
    assert.strictEqual(isValidSignature(body, undefined), false);
});

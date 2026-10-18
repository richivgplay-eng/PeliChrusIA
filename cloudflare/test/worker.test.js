const test = require('node:test');
const assert = require('node:assert/strict');

const { allowedOrigin, fetch: handleRequest } = require('../src/index');
const { mapMovie, parseGeminiResponse, validateMessage } =
  require('../src/domain');

test('valida y normaliza consultas', () => {
  assert.equal(validateMessage('  una comedia  '), 'una comedia');
  assert.throws(() => validateMessage('  '));
  assert.throws(() => validateMessage('x'.repeat(501)));
});

test('limita y elimina títulos duplicados de Gemini', () => {
  const result = parseGeminiResponse({
    candidates: [{
      content: {
        parts: [{
          text: JSON.stringify({
            respuesta: 'Aquí tienes películas.',
            titulos: ['Dune', 'Dune', 'Arrival', 'Interstellar', 'Extra'],
          }),
        }],
      },
    }],
  });
  assert.deepEqual(result, {
    respuesta: 'Aquí tienes películas.',
    titulos: ['Dune', 'Arrival', 'Interstellar'],
  });
});

test('formatea las películas para Flutter', () => {
  assert.equal(
    mapMovie(
      {
        title: 'Dune',
        poster_path: '/poster.jpg',
        release_date: '2021-10-22',
        vote_average: 8.1,
      },
      [{ provider_name: 'Max' }],
    ).plataforma,
    'Max',
  );
});

test('acepta el origen de Workers y rechaza orígenes ajenos', () => {
  assert.equal(
    allowedOrigin('https://pelichrus-api.cuenta.workers.dev'),
    true,
  );
  assert.equal(allowedOrigin('https://example.com'), false);
  assert.equal(allowedOrigin('notaurl'), false);
});

test('no permite métodos distintos de POST al endpoint', async () => {
  const response = await handleRequest(
    new Request('https://pelichrus-api.workers.dev/api/recommendations', {
      method: 'GET',
    }),
    {},
  );
  assert.equal(response.status, 405);
});

test('sirve Flutter desde el binding de assets para otras rutas', async () => {
  const response = await handleRequest(
    new Request('https://pelichrus-api.workers.dev/'),
    { ASSETS: { fetch: async () => new Response('flutter-app') } },
  );
  assert.equal(await response.text(), 'flutter-app');
});

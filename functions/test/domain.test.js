const test = require('node:test');
const assert = require('node:assert/strict');

const {
  RequestError,
  mapMovie,
  parseGeminiResponse,
  validateMessage,
} = require('../src/domain');
const { api, checkRateLimit } = require('../index');

test('expone la función de Firebase y aplica límite por IP', () => {
  assert.ok(api);

  const ip = 'test-rate-limit';
  const now = 1_000_000;
  for (let request = 0; request < 10; request += 1) {
    assert.equal(checkRateLimit(ip, now), true);
  }
  assert.equal(checkRateLimit(ip, now), false);
  assert.equal(checkRateLimit(ip, now + 60_000), true);
});

test('valida y normaliza el texto de la consulta', () => {
  assert.equal(validateMessage('  una comedia  '), 'una comedia');
  assert.throws(() => validateMessage('  '), RequestError);
  assert.throws(() => validateMessage('x'.repeat(501)), RequestError);
});

test('limita las recomendaciones y elimina títulos duplicados', () => {
  const result = parseGeminiResponse({
    candidates: [{
      content: {
        parts: [{
          text: JSON.stringify({
            respuesta: 'Aquí tienes películas.',
            titulos: [' Dune ', 'Dune', 'Arrival', 'Interstellar', 'Extra'],
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

test('convierte los resultados de TMDB al formato usado por Flutter', () => {
  assert.deepEqual(
    mapMovie({
      title: 'Dune',
      poster_path: '/poster.jpg',
      release_date: '2021-10-22',
      vote_average: 8.1,
    }, [{ provider_name: 'Max' }, { provider_name: 'Prime Video' }]),
    {
      titulo: 'Dune',
      posterUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
      plataforma: 'Max, Prime Video',
      trailerUrl: 'https://www.youtube.com/results?search_query=Dune%20tr%C3%A1iler',
      anio: '2021',
      puntuacion: '8.1',
    },
  );
});

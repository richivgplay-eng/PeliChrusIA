const MAX_MESSAGE_LENGTH = 500;
const MAX_RECOMMENDATIONS = 3;

class RequestError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.name = 'RequestError';
    this.statusCode = statusCode;
  }
}

function validateMessage(value) {
  if (typeof value !== 'string') {
    throw new RequestError('Envía una consulta de texto.', 400);
  }
  const texto = value.trim();
  if (!texto) {
    throw new RequestError('La consulta no puede estar vacía.', 400);
  }
  if (texto.length > MAX_MESSAGE_LENGTH) {
    throw new RequestError(
      `La consulta no puede superar ${MAX_MESSAGE_LENGTH} caracteres.`,
      400,
    );
  }
  return texto;
}

function parseGeminiResponse(data) {
  const text = data?.candidates?.[0]?.content?.parts
    ?.find((part) => typeof part.text === 'string')
    ?.text;
  if (!text) {
    throw new Error('La respuesta de Gemini no contiene recomendaciones.');
  }

  const generated = JSON.parse(text);
  if (
    typeof generated.respuesta !== 'string' ||
    !Array.isArray(generated.titulos)
  ) {
    throw new Error('Gemini devolvió recomendaciones con formato inválido.');
  }

  const titulos = [...new Set(
    generated.titulos
      .filter((title) => typeof title === 'string')
      .map((title) => title.trim())
      .filter(Boolean),
  )].slice(0, MAX_RECOMMENDATIONS);
  if (titulos.length === 0) {
    throw new Error('Gemini no encontró títulos para recomendar.');
  }
  return { respuesta: generated.respuesta.trim(), titulos };
}

function mapMovie(movie, providers) {
  const title = typeof movie.title === 'string' ? movie.title : 'Sin título';
  const date = typeof movie.release_date === 'string' ? movie.release_date : '';
  const rating = Number(movie.vote_average);
  const names = [...new Set(
    (Array.isArray(providers) ? providers : [])
      .map((provider) => provider.provider_name)
      .filter((name) => typeof name === 'string' && name.trim()),
  )];

  return {
    titulo: title,
    posterUrl: typeof movie.poster_path === 'string'
      ? `https://image.tmdb.org/t/p/w500${movie.poster_path}`
      : '',
    plataforma: names.length
      ? names.join(', ')
      : 'No disponible en streaming',
    trailerUrl: `https://www.youtube.com/results?search_query=${
      encodeURIComponent(`${title} tráiler`)
    }`,
    anio: /^\d{4}/.test(date) ? date.slice(0, 4) : 'Año desconocido',
    puntuacion: Number.isFinite(rating) ? rating.toFixed(1) : 'N/D',
  };
}

module.exports = {
  RequestError,
  mapMovie,
  parseGeminiResponse,
  validateMessage,
};

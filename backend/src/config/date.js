/**
 * Formatea la fecha y hora actual con zona horaria
 * @param void
 * @return string Devuelve la fecha y hora en formato DD/MM/YYYY HH:MM:SS GMT±HH:MM
 */
function formatDate() {
  let date = new Date();  
  const day = String(date.getDate()).padStart(2, '0');
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const year = date.getFullYear();

  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');

  const timezoneOffset = -date.getTimezoneOffset();
  const sign = timezoneOffset >= 0 ? '+' : '-';
  const offsetHours = String(Math.floor(Math.abs(timezoneOffset) / 60)).padStart(2, '0');
  const offsetMinutes = String(Math.abs(timezoneOffset) % 60).padStart(2, '0');

  const timezone = `GMT${sign}${offsetHours}${offsetMinutes}`;

  return `${day}/${month}/${year} ${hours}:${minutes}:${seconds} ${timezone}`;
}

module.exports = { formatDate };
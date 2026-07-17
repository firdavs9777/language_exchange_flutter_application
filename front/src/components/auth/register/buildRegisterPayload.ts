export interface LocationInput { city: string; country: string; coordinates?: [number, number]; }
export interface RegisterForm {
  name: string; username: string; password: string; email: string; gender: string;
  birthDate: string; native_language: string; language_to_learn: string; location: LocationInput;
}

export function buildRegisterPayload(form: RegisterForm) {
  const [birth_year, birth_month, birth_day] = form.birthDate.split('-');
  const { city, country, coordinates } = form.location;
  const formattedAddress = [city, country].filter(Boolean).join(', ');
  const location: any = { formattedAddress, city, country };
  if (coordinates && coordinates.length === 2) { location.type = 'Point'; location.coordinates = coordinates; }
  const username = form.username.trim() ? form.username.trim().toLowerCase() : null;
  return {
    name: form.name, username, password: form.password, email: form.email, bio: '', gender: form.gender, images: [],
    birth_year, birth_month, birth_day,
    native_language: form.native_language, language_to_learn: form.language_to_learn,
    topics: [], termsAccepted: true, location,
  };
}

// File: src/models/user.ts
// Purpose: cover class, instance/static members, member expressions, optional chaining.

// Erwartete Kontexte
//
// • bei User.fullName() → src/models/user.ts ⟩ User.fullName()
// • bei static fromJSON → src/models/user.ts ⟩ User.fromJSON()
// • bei api.client.request → src/models/user.ts ⟩ api.client.request()
// • bei Member-Expressions (window.app.user…) → src/models/user.ts ⟩ window.app.user.profile.address (lang_extra owner)

export class User {
  // CURSOR: 'firstName' (class container shown when available)
  firstName: string;
  lastName: string;

  constructor(first: string, last: string) { // CURSOR: on 'constructor' (Class container)
    this.firstName = first;
    this.lastName = last;
  }

  // CURSOR: on 'fullName' (expect: src/models/user.ts ⟩ User.fullName())
  fullName(): string {
    return `${this.firstName} ${this.lastName}`;
  }

  // CURSOR: on 'fromJSON' (static)
  static fromJSON(obj: Partial<User>): User {
    return new User(obj.firstName ?? "", obj.lastName ?? "");
  }
}

// Nested object to exercise owner extraction
export const api = {
  client: {
    // CURSOR: on 'request' (owner chain extracted: api.client)
    request(path: string) {
      return fetch(path);
    },
  },
};

// Member expressions and optional chaining
const city = (window as any)?.app?.user?.profile?.address?.city;
// CURSOR: on '.profile' or '.address' (owner chain left side inferred)

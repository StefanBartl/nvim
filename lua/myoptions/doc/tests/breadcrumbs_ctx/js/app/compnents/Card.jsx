// File: app/components/Card.jsx
// Purpose: function component, nested object literals, member expressions.

// Erwartete Kontexte
//
// • bei function Card → app/components/Card.jsx ⟩ Card()
// • bei theme.palette.primary → app/components/Card.jsx ⟩ theme.palette
// • bei api.http.get → app/components/Card.jsx ⟩ api.http.get()

export function Card({ title, children }) { // CURSOR: on 'Card' (symbol only)
  const theme = {
    palette: {
      // CURSOR: on 'primary' (owner chain 'theme.palette')
      primary: { main: "#09f" },
    },
  };
  const api = { http: { get(url) { return fetch(url); } } };

  // CURSOR: on 'get' (owner 'api.http')
  return <section className="card">{children}</section>;
}

// Member expression chain example
const x = globalThis?.app?.ui?.theme?.palette?.primary?.main;
// CURSOR: on '.ui' or '.theme' (owner chain inferred)

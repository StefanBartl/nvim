// File: internal/service/service.go
// Purpose: receiver-based methods (pointer/value), free functions, call sites.

// Erwartete Kontexte
//
// • bei func (t *T) M() → internal/service/service.go ⟩ T.M()
// • bei func (t T) V() → internal/service/service.go ⟩ T.V()
// • bei func Helper() → internal/service/service.go ⟩ Helper()
// • beim Aufruf t.M() → je nach Grammar: Wort-Fallback „M“ oder leer; Owner „t“ wird nicht immer geliefert

package service

type T struct{}

// CURSOR: on 'M' (expect: internal/service/service.go ⟩ T.M())
func (t *T) M() {}

func (t T) V() {} // CURSOR: on 'V' (expect: internal/service/service.go ⟩ T.V())

// Free function (no receiver)
func Helper() {} // CURSOR: on 'Helper' (symbol only)

func use() {
    var t = &T{}
    t.M() // CURSOR: on 'M' at call site (may show 'M' via word fallback; no TS owner for call)
}

type Reader interface {
	Read([]byte) (int, error)
}

type MyReader struct{}

func (MyReader) Read(p []byte) (int, error) {
	return 0, nil
}



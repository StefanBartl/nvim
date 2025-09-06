# File: pkg/a.py
# Purpose: class, instance/staticmethod, attribute owners, module-level functions.
#
# Erwartete Kontexte
#
# • bei def m(self…) → pkg/a.py ⟩ A.m()
# • bei @staticmethod def s() → pkg/a.py ⟩ A.s()
# • bei b.value = 42 → pkg/a.py ⟩ b
# • bei def helper → pkg/a.py ⟩ helper()

class A:
    # CURSOR: on 'm' (expect: pkg/a.py ⟩ A.m())
    def m(self, x: int) -> int:
        return x + 1

    # CURSOR: on 's' (staticmethod)
    @staticmethod
    def s() -> str:
        return "S"

# Attribute owner fallback
class B:
    def __init__(self) -> None:
        self.value = 0  # CURSOR: on 'value' (owner 'self' not shown; class B as container in some grammars)

b = B()
b.value = 42           # CURSOR: on 'b.value' (owner 'b')
name = b.__class__.__name__  # CURSOR: on '__class__' (owner chain from attribute)

# Module-level function
def helper(y: int) -> int:  # CURSOR: on 'helper' (no container → symbol only)
    return y * 2

/**
 * Simple Node.js script to test nvim-dap.
 * Intentional issues:
 * 1. Promise rejection not handled
 * 2. Type assumption error
 */

function fetchUser(id) {
  return new Promise((resolve, reject) => {
    if (id !== 1) {
      reject(new Error("User not found"));
    }
    resolve({ name: "Alice", age: 30 });
  });
}

async function main() {
  const user = await fetchUser(2);

  // Intentional logic error: assuming age is a string
  const nextYearAge = user.age + "1";

  console.log("Next year age:", nextYearAge);
}

main();

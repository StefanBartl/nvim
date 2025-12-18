require("autocmds.patches").validate_all(function(results)
  print("Validation complete:", #results)
end)

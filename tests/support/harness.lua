local Harness = { checks = 0, failures = {} }

function Harness.check(condition, label)
  Harness.checks = Harness.checks + 1
  if not condition then Harness.failures[#Harness.failures + 1] = label end
end

function Harness.equal(actual, expected, label)
  Harness.check(actual == expected,
    label .. " (expected " .. tostring(expected) .. ", got " .. tostring(actual) .. ")")
end

function Harness.finish()
  if #Harness.failures > 0 then
    error(table.concat(Harness.failures, "\n"), 0)
  end
  print(("clean ui core: %d checks passed"):format(Harness.checks))
end

return Harness

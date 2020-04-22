std = "lua51"
max_line_length = false
allow_defined_top = true
exclude_files = {
   ".luacheckrc"
}

ignore = {
   "113",      -- Accessing an undefined global variable.
   "212",        -- Unused argument.
}

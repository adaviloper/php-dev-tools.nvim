local Config = {
  test_utils = {}
}

function Config.set(opts)
  for _, project_specs in ipairs(opts.test_utils) do
    Config.test_utils[vim.fs.normalize(project_specs.dir)] = project_specs
  end
end

return Config

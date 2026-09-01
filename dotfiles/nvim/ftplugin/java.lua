local jdtls = require('jdtls')

local nvchad_on_attach = require('nvchad.configs.lspconfig').on_attach
local capabilities = require('nvchad.configs.lspconfig').capabilities

local debug_paths = vim.fn.glob("/run/current-system/sw/share/vscode/extensions/vscjava.vscode-java-debug/server/com.microsoft.java.debug.plugin-*.jar", true, true)
if #debug_paths == 0 then
  debug_paths = vim.fn.glob(vim.fn.expand("~/.nix-profile/share/vscode/extensions/vscjava.vscode-java-debug/server/com.microsoft.java.debug.plugin-*.jar"), true, true)
end

local bundles = {}
if #debug_paths > 0 then
  table.insert(bundles, debug_paths[1])
else
  vim.notify("Không tìm thấy vscode-java-debug từ Nix!", vim.log.levels.WARN)
end

local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = vim.fn.stdpath('data') .. '/site/java/workspace-root/' .. project_name

local config = {
  cmd = {
    'jdtls',
    '-data', workspace_dir
  },
  root_dir = require('jdtls.setup').find_root({'.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle'}),
  init_options = {
    bundles = bundles,
  },
  -- Với các project không có Maven/Gradle (unmanaged), jdtls tự đoán source
  -- folder và hay đoán sai khi có nhiều package con (mỗi thư mục package bị
  -- tách thành 1 source root riêng -> import giữa các package báo lỗi).
  -- Khai báo thẳng root project là source path để khỏi phải đoán.
  -- Setting này bị bỏ qua nếu project có pom.xml/build.gradle nên không ảnh
  -- hưởng project dùng build tool.
  settings = {
    java = {
      project = {
        sourcePaths = { '.' },
      },
    },
  },
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    nvchad_on_attach(client, bufnr)
    require('jdtls').setup_dap({ hotcodereplace = 'auto' })
    require('jdtls.dap').setup_dap_main_class_configs()
  end,
}

jdtls.start_or_attach(config)

return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  { import = "nvchad.blink.lazyspec" },

  {
    "nvim-treesitter/nvim-treesitter",
    build = ':TSUpdate',
    opts = {
      ensure_installed = {
        "vim", "lua", "vimdoc", "markdown", "markdown_inline",
        "cpp", "c", "python", "nix", "gdscript", "bash", 
        "java" -- ĐÃ THÊM JAVA ĐỂ KÍCH HOẠT RAINBOW BRACKETS & HIGHLIGHT
      },
      highlight = {
        enable = true,
      },
    },
  },

  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {},
    },
  },

  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      automatic_installation = false,
    }
  },

  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "BufRead",
    opts = {},
  },

  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
    keys = {
        { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
    },
  },

  -- RAINBOW BRACKET
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local rainbow_delimiters = require("rainbow-delimiters")

      require("rainbow-delimiters.setup").setup {
        strategy = {
          [""] = rainbow_delimiters.strategy["global"],
          vim = rainbow_delimiters.strategy["local"],
        },
        query = {
          [""] = "rainbow-delimiters",
          lua = "rainbow-blocks",
        },
        highlight = {
          "RainbowDelimiterRed",
          "RainbowDelimiterYellow",
          "RainbowDelimiterBlue",
          "RainbowDelimiterOrange",
          "RainbowDelimiterGreen",
          "RainbowDelimiterViolet",
          "RainbowDelimiterCyan",
        },
      }
      vim.api.nvim_set_hl(0, 'RainbowDelimiterRed', { fg = '#E06C75' })
      vim.api.nvim_set_hl(0, 'RainbowDelimiterYellow', { fg = '#E5C07B' })
      vim.api.nvim_set_hl(0, 'RainbowDelimiterBlue', { fg = '#61AFEF' })
      vim.api.nvim_set_hl(0, 'RainbowDelimiterOrange', { fg = '#D19A66' })
      vim.api.nvim_set_hl(0, 'RainbowDelimiterGreen', { fg = '#98C379' })
      vim.api.nvim_set_hl(0, 'RainbowDelimiterViolet', { fg = '#C678DD' })
      vim.api.nvim_set_hl(0, 'RainbowDelimiterCyan', { fg = '#56B6C2' })
    end,
  },

  -- LINE & SCOPE
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "BufReadPost",
    dependencies = { "HiPhish/rainbow-delimiters.nvim" }, 
    opts = function(_, opts)
      vim.api.nvim_set_hl(0, 'IblScopeWhite', { fg = '#FFFFFF', default = true })
      opts.indent = {
        char = "│",
        tab_char = "│",
      }
      
      opts.scope = {
        enabled = true,
        show_start = true,
        show_end = true,
        highlight = { "IblScopeWhite" },
        include = {
          node_type = {
            ["*"] = {
              "function", "method", "for", "while", "if", "switch", 
              "try", "catch", "block", "compound_statement", 
              "chunk", "block_body",         
            },
          },
        },
      }
      return opts
    end,
  },

  -- CODE RUNNER
  {
    "CRAG666/code_runner.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    cmd = { "RunCode", "RunFile", "RunProject", "RunClose" },
    keys = {
      { "<F9>", "<cmd>RunFile<CR>", desc = "Run File (Code Runner)" },
    },
    config = function()
      require("code_runner").setup({
        mode = "float", 
        float = {
          border = "rounded",
          width = 0.8,
          height = 0.8,
          x = 0.5,
          y = 0.5,
        },
        
        filetype = {
          python = "python3 -u",
          cpp = {
            "cd $dir &&",
            "g++ $fileName -o $fileNameWithoutExt &&",
            "./$fileNameWithoutExt"
          },
          c = {
            "cd $dir &&",
            "gcc $fileName -o $fileNameWithoutExt &&",
            "./$fileNameWithoutExt"
          },
          java = [[cd $dir && raw_name=$(echo $fileNameWithoutExt | tr -d "'"); pkg=$(awk '/^package/ {gsub(/;/,""); print $2}' $fileName); if [ -z "$pkg" ]; then cls="$raw_name"; else cls="$pkg.$raw_name"; fi; root_dir=$PWD; while [ "$root_dir" != "/" ] && [ ! -f "$root_dir/pom.xml" ]; do root_dir=$(dirname "$root_dir"); done; if [ -f "$root_dir/pom.xml" ]; then cd "$root_dir" && mvn -q compile exec:java -Dexec.mainClass="$cls"; else cd $dir && javac $fileName && java "$cls"; fi]],
          sh = "bash",
        },
      })
    end,
  },

  -- DEBUGGER
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end

      local codelldb_cmd = 'codelldb'
      local nix_path = vim.fn.expand("~/.nix-profile/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb")
      local sys_path = "/run/current-system/sw/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb"
      
      if vim.fn.filereadable(nix_path) == 1 then
        codelldb_cmd = nix_path
      elseif vim.fn.filereadable(sys_path) == 1 then
        codelldb_cmd = sys_path
      end

      dap.adapters.codelldb = {
        type = 'server',
        port = "${port}",
        executable = {
          command = codelldb_cmd,
          args = {"--port", "${port}"},
        }
      }

      dap.configurations.cpp = {
        {
          name = "Launch C++ (Debug)",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
        },
      }
      dap.configurations.c = dap.configurations.cpp 

      dap.adapters.python = function(cb, config)
        if config.request == 'attach' then
          local port = (config.connect or config).port
          local host = (config.connect or config).host or '127.0.0.1'
          cb({ type = 'server', port = assert(port, 'Requires connect.port'), host = host, options = { source_filetype = 'python' } })
        else
          cb({
            type = 'executable',
            command = 'python3', -- ĐÃ SỬA THÀNH python3 ĐỂ CHẠY TRÊN NIXOS
            args = { '-m', 'debugpy.adapter' },
            options = { source_filetype = 'python' }
          })
        end
      end
      
      dap.configurations.python = {
        {
          type = 'python',
          request = 'launch',
          name = "Launch Python (Debug)",
          program = "${file}",
          pythonPath = function()
            return 'python3'
          end,
        },
      }
    end,

    keys = {
      { "<F8>", "<cmd>lua require'dap'.continue()<CR>", desc = "Debug: Start/Continue" },
      { "<F10>", "<cmd>lua require'dap'.step_over()<CR>", desc = "Debug: Step Over" },
      { "<F11>", "<cmd>lua require'dap'.step_into()<CR>", desc = "Debug: Step Into" },
      { "<F12>", "<cmd>lua require'dap'.step_out()<CR>", desc = "Debug: Step Out" },
      { "<F5>", "<cmd>lua require'dap'.toggle_breakpoint()<CR>", desc = "Debug: Toggle Breakpoint" },
    },
  },

  -- GIAO DIỆN DEBUG UI
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      require("dapui").setup()
    end,
  },

  -- QUẢN LÝ GIT
  {
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>lg", "<cmd>LazyGit<cr>", desc = "Mở Lazygit" },
    },
  },

  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
  },
}

local M = {}

-- Check if a command is available
local function has_cmd(cmd)
  return vim.fn.executable(cmd) == 1
end

-- Requirements checkers
M.requirements = {
  swift = function() return has_cmd("swift") end,
  swiftc = function() return has_cmd("swiftc") end,
  xcodegen = function() return has_cmd("xcodegen") end,
  cargo = function() return has_cmd("cargo") end,
  rustc = function() return has_cmd("rustc") end,
  go = function() return has_cmd("go") end,
  python3 = function() return has_cmd("python3") end,
  lua = function() return has_cmd("lua") end,
  gcc = function() return has_cmd("gcc") or has_cmd("clang") end,
  ["g++"] = function() return has_cmd("g++") or has_cmd("clang++") end,
  make = function() return has_cmd("make") end,
  cmake = function() return has_cmd("cmake") end,
  kotlin = function() return has_cmd("kotlin") or has_cmd("kotlinc") end,
  gradle = function() return has_cmd("gradle") or has_cmd("./gradlew") end,
}

-- Check if all requirements are met
function M.check_requirements(reqs)
  if not reqs or #reqs == 0 then return true, {} end

  local missing = {}
  for _, req in ipairs(reqs) do
    local checker = M.requirements[req]
    if checker and not checker() then
      table.insert(missing, req)
    end
  end

  return #missing == 0, missing
end

M.templates = {
  -- Swift templates
  {
    name = "Swift File",
    lang = "swift",
    icon = "",
    type = "file",
    extension = "swift",
    requires = { "swift" },
    install_hint = "Install Xcode or Swift toolchain",
    content = [[
import Foundation

print("Hello, Swift!")
]],
  },
  {
    name = "Swift Package (SPM)",
    lang = "swift",
    icon = "",
    type = "project",
    requires = { "swift" },
    install_hint = "Install Xcode or Swift toolchain",
    create = function(path, name)
      -- Convert name to valid Swift identifier (replace hyphens/spaces with underscores, ensure starts with letter)
      local swift_name = name:gsub("[-_%s]+", "_"):gsub("^[^%a]", "")
      if swift_name == "" then swift_name = "App" end
      -- Convert to PascalCase for struct name
      local struct_name = swift_name:gsub("_(%l)", function(c) return c:upper() end):gsub("^%l", string.upper)

      return {
        pre = function()
          vim.fn.mkdir(path, "p")
          vim.fn.mkdir(path .. "/Sources/" .. name, "p")
          vim.fn.mkdir(path .. "/Tests/" .. name .. "Tests", "p")

          -- Package.swift with test target
          local package_content = string.format([[
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "%s",
    targets: [
        .executableTarget(name: "%s"),
        .testTarget(
            name: "%sTests",
            dependencies: ["%s"]
        ),
    ]
)
]], name, name, name, name)
          local package_file = io.open(path .. "/Package.swift", "w")
          if package_file then
            package_file:write(package_content)
            package_file:close()
          end

          -- Main source file
          local main_content = string.format([[
import Foundation

@main
struct %s {
    static func main() {
        print("Hello, %s!")
        print("2 + 3 = \(add(2, 3))")
    }
}

public func add(_ a: Int, _ b: Int) -> Int {
    return a + b
}
]], struct_name, name)
          local main_file = io.open(path .. "/Sources/" .. name .. "/" .. name .. ".swift", "w")
          if main_file then
            main_file:write(main_content)
            main_file:close()
          end

          -- Test file (use underscore version for import since SPM converts hyphens to underscores)
          local module_name = name:gsub("-", "_")
          local test_content = string.format([[
import Testing
@testable import %s

@Test func testAdd() {
    #expect(add(2, 3) == 5)
    #expect(add(-1, 1) == 0)
    #expect(add(0, 0) == 0)
}
]], module_name)
          local test_file = io.open(path .. "/Tests/" .. name .. "Tests/" .. name .. "Tests.swift", "w")
          if test_file then
            test_file:write(test_content)
            test_file:close()
          end
        end,
        cmd = nil,
        entry_file = path .. "/Sources/" .. name .. "/" .. name .. ".swift",
      }
    end,
  },
  {
    name = "Xcode Project",
    lang = "swift",
    icon = "",
    type = "project",
    requires = { "swift", "xcodegen" },
    install_hint = "brew install xcodegen",
    create = function(path, name)
      return {
        pre = function()
          vim.fn.mkdir(path, "p")
          local sources_dir = path .. "/Sources"
          vim.fn.mkdir(sources_dir, "p")

          -- Write project.yml for xcodegen
          local project_yml = string.format([[
name: %s
targets:
  %s:
    type: application
    platform: macOS
    deploymentTarget: "14.0"
    sources:
      - Sources
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.example.%s
]], name, name, name:lower())

          local yml_file = io.open(path .. "/project.yml", "w")
          if yml_file then
            yml_file:write(project_yml)
            yml_file:close()
          end

          -- Write main.swift
          local main_content = string.format([[
import Foundation

print("Hello, %s!")
]], name)
          local main_file = io.open(sources_dir .. "/main.swift", "w")
          if main_file then
            main_file:write(main_content)
            main_file:close()
          end
        end,
        cmd = vim.fn.executable("xcodegen") == 1
          and string.format("cd %s && xcodegen generate", vim.fn.shellescape(path))
          or nil,
        entry_file = path .. "/Sources/main.swift",
        post_warning = vim.fn.executable("xcodegen") ~= 1
          and "xcodegen not found. Install with: brew install xcodegen"
          or nil,
      }
    end,
  },

  -- C++ templates
  {
    name = "C++ File",
    lang = "cpp",
    icon = "",
    type = "file",
    extension = "cpp",
    requires = { "g++" },
    install_hint = "Install g++ or clang++",
    content = [[
#include <iostream>

int main() {
    std::cout << "Hello, C++!" << std::endl;
    return 0;
}
]],
  },
  {
    name = "C++ Project (Makefile)",
    lang = "cpp",
    icon = "",
    type = "project",
    requires = { "g++", "make" },
    install_hint = "Install g++/clang++ and make",
    create = function(path, name)
      return {
        pre = function()
          vim.fn.mkdir(path .. "/src", "p")
          vim.fn.mkdir(path .. "/include", "p")

          -- Main.cpp
          local main_content = string.format([[
#include <iostream>

int main() {
    std::cout << "Hello, %s!" << std::endl;
    return 0;
}
]], name)
          local main_file = io.open(path .. "/src/main.cpp", "w")
          if main_file then
            main_file:write(main_content)
            main_file:close()
          end

          -- Makefile
          local makefile = string.format([[
CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -I include
SRC_DIR = src
BUILD_DIR = build
TARGET = %s

SRCS = $(wildcard $(SRC_DIR)/*.cpp)
OBJS = $(SRCS:$(SRC_DIR)/%%.cpp=$(BUILD_DIR)/%%.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(OBJS) -o $@

$(BUILD_DIR)/%%.o: $(SRC_DIR)/%%.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR):
	mkdir -p $@

clean:
	rm -rf $(BUILD_DIR) $(TARGET)

run: $(TARGET)
	./$(TARGET)

.PHONY: all clean run
]], name)
          local makefile_file = io.open(path .. "/Makefile", "w")
          if makefile_file then
            makefile_file:write(makefile)
            makefile_file:close()
          end
        end,
        cmd = nil, -- No async command needed
        entry_file = path .. "/src/main.cpp",
      }
    end,
  },
  {
    name = "C++ Project (CMake)",
    lang = "cpp",
    icon = "",
    type = "project",
    requires = { "g++", "cmake" },
    install_hint = "brew install cmake",
    create = function(path, name)
      return {
        pre = function()
          vim.fn.mkdir(path .. "/src", "p")
          vim.fn.mkdir(path .. "/include", "p")

          -- Main.cpp
          local main_content = string.format([[
#include <iostream>

int main() {
    std::cout << "Hello, %s!" << std::endl;
    return 0;
}
]], name)
          local main_file = io.open(path .. "/src/main.cpp", "w")
          if main_file then
            main_file:write(main_content)
            main_file:close()
          end

          -- CMakeLists.txt
          local cmake = string.format([[
cmake_minimum_required(VERSION 3.16)
project(%s LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(${PROJECT_NAME} src/main.cpp)
target_include_directories(${PROJECT_NAME} PRIVATE include)
]], name)
          local cmake_file = io.open(path .. "/CMakeLists.txt", "w")
          if cmake_file then
            cmake_file:write(cmake)
            cmake_file:close()
          end
        end,
        cmd = nil,
        entry_file = path .. "/src/main.cpp",
      }
    end,
  },

  -- Lua templates
  {
    name = "Lua File",
    lang = "lua",
    icon = "",
    type = "file",
    extension = "lua",
    requires = { "lua" },
    install_hint = "brew install lua",
    content = [[
print("Hello, Lua!")
]],
  },
  {
    name = "Lua Project",
    lang = "lua",
    icon = "",
    type = "project",
    requires = { "lua" },
    install_hint = "brew install lua",
    create = function(path, name)
      return {
        pre = function()
          vim.fn.mkdir(path .. "/src", "p")

          local main_content = string.format([[
-- %s

local M = {}

function M.run()
    print("Hello, %s!")
end

M.run()

return M
]], name, name)
          local main_file = io.open(path .. "/src/main.lua", "w")
          if main_file then
            main_file:write(main_content)
            main_file:close()
          end
        end,
        cmd = nil,
        entry_file = path .. "/src/main.lua",
      }
    end,
  },

  -- Rust templates
  {
    name = "Rust File",
    lang = "rust",
    icon = "",
    type = "file",
    extension = "rs",
    requires = { "rustc" },
    install_hint = "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh",
    content = [[
fn main() {
    println!("Hello, Rust!");
}
]],
  },
  {
    name = "Rust Project (Cargo)",
    lang = "rust",
    icon = "",
    type = "project",
    requires = { "cargo" },
    install_hint = "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh",
    create = function(path, name)
      return {
        pre = function()
          vim.fn.mkdir(path, "p")
        end,
        cmd = string.format(
          "cd %s && cargo init --name %s",
          vim.fn.shellescape(vim.fn.fnamemodify(path, ":h")),
          vim.fn.shellescape(name)
        ),
        entry_file = path .. "/src/main.rs",
      }
    end,
  },

  -- Go templates
  {
    name = "Go File",
    lang = "go",
    icon = "",
    type = "file",
    extension = "go",
    requires = { "go" },
    install_hint = "brew install go",
    content = [[
package main

import "fmt"

func main() {
    fmt.Println("Hello, Go!")
}
]],
  },
  {
    name = "Go Module",
    lang = "go",
    icon = "",
    type = "project",
    requires = { "go" },
    install_hint = "brew install go",
    create = function(path, name)
      return {
        pre = function()
          vim.fn.mkdir(path, "p")

          local main_content = string.format([[
package main

import "fmt"

func main() {
    fmt.Println("Hello, %s!")
}

func Add(a, b int) int {
    return a + b
}
]], name)
          local main_file = io.open(path .. "/main.go", "w")
          if main_file then
            main_file:write(main_content)
            main_file:close()
          end

          -- Test file
          local test_content = [[
package main

import "testing"

func TestAdd(t *testing.T) {
    result := Add(2, 3)
    if result != 5 {
        t.Errorf("Add(2, 3) = %d; want 5", result)
    }
}
]]
          local test_file = io.open(path .. "/main_test.go", "w")
          if test_file then
            test_file:write(test_content)
            test_file:close()
          end
        end,
        cmd = string.format(
          "cd %s && go mod init %s",
          vim.fn.shellescape(path),
          vim.fn.shellescape(name)
        ),
        entry_file = path .. "/main.go",
      }
    end,
  },

  -- Python templates
  {
    name = "Python File",
    lang = "python",
    icon = "",
    type = "file",
    extension = "py",
    requires = { "python3" },
    install_hint = "brew install python3",
    content = [[
def main():
    print("Hello, Python!")

if __name__ == "__main__":
    main()
]],
  },
  {
    name = "Python Project (venv)",
    lang = "python",
    icon = "",
    type = "project",
    requires = { "python3" },
    install_hint = "brew install python3",
    create = function(path, name)
      return {
        pre = function()
          vim.fn.mkdir(path, "p")
          vim.fn.mkdir(path .. "/tests", "p")

          local main_content = string.format([[
"""
%s - A Python project
"""

def add(a: int, b: int) -> int:
    """Add two numbers."""
    return a + b

def main():
    print("Hello, %s!")
    print(f"2 + 3 = {add(2, 3)}")

if __name__ == "__main__":
    main()
]], name, name)
          local main_file = io.open(path .. "/main.py", "w")
          if main_file then
            main_file:write(main_content)
            main_file:close()
          end

          -- Create test file
          local test_content = [[
"""Tests for main module."""
import unittest
from main import add

class TestMain(unittest.TestCase):
    def test_add(self):
        self.assertEqual(add(2, 3), 5)
        self.assertEqual(add(-1, 1), 0)
        self.assertEqual(add(0, 0), 0)

if __name__ == "__main__":
    unittest.main()
]]
          local test_file = io.open(path .. "/tests/test_main.py", "w")
          if test_file then
            test_file:write(test_content)
            test_file:close()
          end

          -- Create requirements.txt
          local req_file = io.open(path .. "/requirements.txt", "w")
          if req_file then
            req_file:write("# Add your dependencies here\npytest>=7.0.0\n")
            req_file:close()
          end
        end,
        cmd = string.format(
          "cd %s && python3 -m venv venv",
          vim.fn.shellescape(path)
        ),
        entry_file = path .. "/main.py",
        post_warning = "Activate venv with: source venv/bin/activate",
      }
    end,
  },

  -- Kotlin templates
  {
    name = "Kotlin Script",
    lang = "kotlin",
    icon = "",
    type = "file",
    extension = "kts",
    requires = { "kotlin" },
    install_hint = "brew install kotlin",
    content = [[
fun main() {
    println("Hello, Kotlin!")
}

main()
]],
  },
  {
    name = "Kotlin Project (Gradle)",
    lang = "kotlin",
    icon = "",
    type = "project",
    requires = { "kotlin", "gradle" },
    install_hint = "brew install kotlin gradle",
    create = function(path, name)
      return {
        pre = function()
          vim.fn.mkdir(path .. "/src/main/kotlin", "p")
          vim.fn.mkdir(path .. "/src/test/kotlin", "p")

          -- Main.kt
          local main_content = string.format([[
package %s

fun add(a: Int, b: Int): Int = a + b

fun main() {
    println("Hello, %s!")
    println("2 + 3 = ${add(2, 3)}")
}
]], name:lower(), name)
          local main_file = io.open(path .. "/src/main/kotlin/Main.kt", "w")
          if main_file then
            main_file:write(main_content)
            main_file:close()
          end

          -- Test file
          local test_content = string.format([[
package %s

import kotlin.test.Test
import kotlin.test.assertEquals

class MainTest {
    @Test
    fun testAdd() {
        assertEquals(5, add(2, 3))
        assertEquals(0, add(-1, 1))
        assertEquals(0, add(0, 0))
    }
}
]], name:lower())
          local test_file = io.open(path .. "/src/test/kotlin/MainTest.kt", "w")
          if test_file then
            test_file:write(test_content)
            test_file:close()
          end

          -- build.gradle.kts
          local gradle_content = string.format([[
plugins {
    kotlin("jvm") version "1.9.21"
    application
}

group = "%s"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    testImplementation(kotlin("test"))
}

tasks.test {
    useJUnitPlatform()
}

application {
    mainClass.set("%s.MainKt")
}
]], name:lower(), name:lower())
          local gradle_file = io.open(path .. "/build.gradle.kts", "w")
          if gradle_file then
            gradle_file:write(gradle_content)
            gradle_file:close()
          end

          -- settings.gradle.kts
          local settings_content = string.format([[
rootProject.name = "%s"
]], name)
          local settings_file = io.open(path .. "/settings.gradle.kts", "w")
          if settings_file then
            settings_file:write(settings_content)
            settings_file:close()
          end
        end,
        cmd = nil,
        entry_file = path .. "/src/main/kotlin/Main.kt",
        post_warning = vim.fn.executable("gradle") ~= 1 and vim.fn.executable("./gradlew") ~= 1
          and "Gradle not found. Install with: brew install gradle"
          or nil,
      }
    end,
  },
}

function M.get_all()
  return M.templates
end

function M.get_by_lang(lang)
  return vim.tbl_filter(function(t)
    return t.lang == lang
  end, M.templates)
end

-- Get templates grouped by availability
function M.get_grouped()
  local available = {}
  local unavailable = {}

  for _, template in ipairs(M.templates) do
    local is_available, missing = M.check_requirements(template.requires)
    local t = vim.tbl_extend("force", template, { missing = missing })

    if is_available then
      table.insert(available, t)
    else
      table.insert(unavailable, t)
    end
  end

  return available, unavailable
end

return M

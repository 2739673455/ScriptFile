$env.config.buffer_editor = "code"
$env.config.show_banner = false

# >>> mamba initialize >>>
$env.MAMBA_EXE = "C:\\Users\\kodey\\AppData\\Local\\micromamba\\micromamba.exe"
$env.MAMBA_ROOT_PREFIX = "C:\\Users\\kodey\\micromamba"
# 添加 condabin 到环境变量
$env.PATH = ($env.PATH | prepend $"($env.MAMBA_ROOT_PREFIX)/condabin")

def --env "conda activate"  [name: string] {
    if $env.MAMBA_SHLVL? == null { $env.MAMBA_SHLVL = 0 }
    # 获取环境变量
    let new_env = ^($env.MAMBA_EXE) shell activate --shell nu $name | lines | parse --regex '(.*) = (.+)' | transpose --header-row | into record
    # 替换 PATH 为 Path
    let new_env = $new_env | insert Path ($new_env.PATH) | reject PATH
    # 更新环境变量
    $new_env | load-env
    $env.PATH = $env.PATH | split row (char esep) | each {|x| $x | str trim } | where {|x| $x != "" }
}

def --env "conda deactivate"  [] {
    # 更新环境变量
    for x in (micromamba shell deactivate --shell nu | lines) {
        if ("hide-env" in $x) {
            hide-env (($x | parse "hide-env {var}").0.var)
        } else if ($x =~ "=") {
            let keyValue = $x | parse '{key} = {value}'
            if ($keyValue | is-empty) == false {
                let k = $keyValue.0.key
                let v = $keyValue.0.value
                if $k == "PATH" {
                    # 将 PATH 转换为列表
                    let path_list = ($v | split row ";" | each {|x| $x | str trim } | where {|x| $x != "" })
                    load-env { Path: $path_list }
                } else {
                    load-env { $k: $v }
                }
            }
        }
    }
}

alias conda = micromamba
# <<< mamba initialize <<<

source ~/.config/nushell/starship.nu
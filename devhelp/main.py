# In regards to why this is a python script instead of just a bash function:
# Rich for Python will detect the current console size and dynamically
# adjust the table to fit inside of it, word wrapping if necessary.

from rich.console import Console
from rich.table import Table

console = Console()

tools_table = Table(title="Included CLI and TUI Tools")

tools_table.add_column("Name", style="cyan", no_wrap=True)
tools_table.add_column("Command\n", style="cyan", no_wrap=True)
tools_table.add_column("Written in", style="magenta", no_wrap=True)
tools_table.add_column("Purpose", style="green")
tools_table.add_column("Included in", no_wrap=True)

tools_table.add_row("sudo", "", "C", "Run commands as another user", "Code-Server")
tools_table.add_row("git", "", "C", "Version Control", "Code-Server")
tools_table.add_row("Github CLI", "gh", "Go", "Github official CLI", "Dev Barge")
# tools_table.add_row("homebrew", "brew", "Ruby", "Package manager", "Dev Barge")
tools_table.add_row("curl", "", "C", "Downloading things", "Code-Server")
tools_table.add_row("wget", "", "C", "Downloading things", "Code-Server")
tools_table.add_row("make", "", "C", "Build automation", "Dev Barge")
tools_table.add_row("just", "", "Rust", "Command runner - replaces Make", "Dev Barge")
tools_table.add_row("zoxide", "z/zi", "Rust", "Smarter cd command", "Dev Barge")
tools_table.add_row("fzf", "", "Go", "Fuzzy finder", "Dev Barge")
tools_table.add_row("ripgrep", "rg", "Rust", "Modern version of grep", "Dev Barge")
tools_table.add_row("uv", "", "Rust", "Manages all things python", "Dev Barge")
tools_table.add_row("npm", "", "Javascript", "Node Package Manager", "Dev Barge")
tools_table.add_row("pnpm", "", "Javascript", "Performant Node Package Manager", "Dev Barge")
tools_table.add_row("nvm", "", "Shell", "Node Version Manager for Javascript", "Dev Barge")
tools_table.add_row("node", "", "C++", "Javascript runtime", "Dev Barge")
tools_table.add_row("tmux", "", "C", "Screen multiplexer", "Dev Barge")
tools_table.add_row("batcat", "bat", "Rust", "Better `cat` with color", "Dev Barge")
tools_table.add_row("htop", "", "C", "System process viewer", "Code-Server")
tools_table.add_row("nano", "", "C", "Terminal text editor", "Code-Server")
tools_table.add_row("vim-tiny", "vi", "C", "Terminal text editor", "Code-Server")
tools_table.add_row("neovim", "nvim", "C", "Terminal IDE", "Dev Barge")

###################
# FUNCTIONS TABLE #
###################

func_table = Table(title="Bash Functions")

func_table.add_column("Command\n", style="cyan", no_wrap=True)
func_table.add_column("Purpose", style="green")

func_table.add_row("fsh", "Fuzzy shell history")
func_table.add_row("rgf", "Ripgrep by filename")
func_table.add_row("colortest", "Print a 16-bit gradient to test truecolor support")
func_table.add_row("tkhelp", "Display this help message")

###################
# WELCOME MESSAGE #
###################

console.print(tools_table)
console.print("[italic]Command is same as name if blank.[/italic] \n")
console.print("[italic]See more functions available in /home/coder/.functions[/italic] \n")
console.print(func_table)
console.print("\n[italic]Remember to 'tmux a'[/italic] \n")
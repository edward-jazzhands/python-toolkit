from rich.console import Console
from rich.table import Table
from pyfiglet import figlet_format

console = Console()

# Having this banner be dynamically generated means it'll adjust
# to the terminal size and word wrap if necessary.
banner = figlet_format("Programming Toolkit", font="smslant")

welcome_message = f"""{'=' * 30}
[green]Programming Toolkit Container[/green]
           by Edward Jazzhands

OS Base: [cyan]Debian Slim[/cyan]
{'=' * 30}"""

###############
# TOOLS TABLE #
###############

tools_table = Table(title="Included CLI and TUI Tools")

tools_table.add_column("Name", style="cyan", no_wrap=True)
tools_table.add_column("Command\n", style="cyan", no_wrap=True)
tools_table.add_column("Written in", style="magenta", no_wrap=True)
tools_table.add_column("Purpose", style="green")

tools_table.add_row("sudo", "", "C", "Run commands as another user")
tools_table.add_row("git", "", "C", "Version Control")
tools_table.add_row("Github CLI", "gh", "Go", "Github official CLI")
tools_table.add_row("GNU-PG", "gpg", "C", "Encryption and signing")
tools_table.add_row("gopass", "", "Go", "Password manager using GPG")
tools_table.add_row("curl", "", "C", "Downloading things")
tools_table.add_row("wget", "", "C", "Downloading things")
tools_table.add_row("homebrew", "brew", "Ruby", "Package manager")
tools_table.add_row("uv", "", "Rust", "Manages all things python")
tools_table.add_row("npm", "", "Javascript", "Node Package Manager")
tools_table.add_row("pnpm", "", "Javascript", "Performant Node Package Manager")
tools_table.add_row("nvm", "", "Shell", "Node Version Manager for Javascript")
tools_table.add_row("node", "", "C++", "Javascript runtime")
tools_table.add_row("typescript", "tsc", "Javascript", "TypeScript compiler")
tools_table.add_row("tmux", "", "C", "Screen multiplexer")
tools_table.add_row("make", "", "C", "Build automation")
tools_table.add_row("just", "", "Rust", "Command runner - replaces Make")
tools_table.add_row("nano", "", "C", "Terminal text editor")
tools_table.add_row("neovim", "nvim", "C", "Terminal text editor with TUI")
tools_table.add_row("batcat", "bat", "Rust", "Cat with color")
tools_table.add_row("btop", "", "C++", "System process viewer")
tools_table.add_row("zoxide", "z", "Rust", "Smarter cd command")
tools_table.add_row("fzf", "", "Go", "Fuzzy finder")
tools_table.add_row("ripgrep", "rg", "Rust", "Modern version of grep")
tools_table.add_row("nox", "", "Python", "Environment testing for Python")
tools_table.add_row("rich-cli", "rich", "Python", "Syntax highlighting in terminal")
tools_table.add_row("ducktools-pytui", "pytui", "Python", "Experimental Python managing TUI")
tools_table.add_row("harlequin", "", "Python", "SQLite database viewer and editor")
tools_table.add_row("lazygit", "", "Go", "Terminal UI for git")
tools_table.add_row("cloctui", "", "Python/Perl", "Terminal UI for CLOC")
tools_table.add_row("hugo", "", "Go", "Static site generator")

###################
# FUNCTIONS TABLE #
###################

func_table = Table(title="Bash Functions")

func_table.add_column("Command\n", style="cyan", no_wrap=True)
func_table.add_column("Purpose", style="green")

func_table.add_row("fcd", "Fuzzy cd into a directory")
func_table.add_row("fsh", "Fuzzy shell history")
func_table.add_row("rgf", "Ripgrep by filename")
func_table.add_row("colortest", "Print a 16-bit gradient to test truecolor support")
func_table.add_row("resource", "Re-source the .bashrc file")
func_table.add_row("activate", "Activate the Python virtual environment")
func_table.add_row("bashrc", "Open the .bashrc file in nano")
func_table.add_row("tkhelp", "Display this help message")

###################
# WELCOME MESSAGE #
###################

console.print(f"\n[cyan]{banner}[/cyan]")
console.print(welcome_message)
console.print(tools_table)
console.print("[italic]Command is same as name if blank[/italic] \n")
console.print(func_table)
console.print("\n[italic]Remember to 'tmux a'[/italic] \n")
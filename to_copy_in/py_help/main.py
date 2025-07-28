from rich.console import Console
from rich.table import Table
from pyfiglet import figlet_format

console = Console()

banner = figlet_format("Python Toolkit", font="smslant")

welcome_message = f"""{'=' * 30}
[green]Python Toolkit Container[/green]
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
tools_table.add_row("curl", "", "C", "Downloading things")
tools_table.add_row("wget", "", "C", "Downloading things")
tools_table.add_row("homebrew", "brew", "Ruby", "Package manager")
tools_table.add_row("GNU Pass", "pass", "C", "Password manager")
tools_table.add_row("uv", "", "Rust", "Manages all things python")
tools_table.add_row("npm", "", "Javascript", "Node Package Manager")
tools_table.add_row("nvm", "", "Shell", "Node Version Manager for Javascript")
tools_table.add_row("node", "", "C++", "Javascript runtime")
tools_table.add_row("tmux", "", "C", "Screen multiplexer")
tools_table.add_row("make", "", "C", "Build automation")
tools_table.add_row("just", "", "Rust", "Command runner - replaces Make")
tools_table.add_row("gulp", "", "Javascript", "Command runner based on node")
tools_table.add_row("nano", "", "C", "Terminal text editor")
tools_table.add_row("batcat", "bat", "Rust", "Cat with color")
tools_table.add_row("fzf", "", "Go", "Fuzzy finder")
tools_table.add_row("ripgrep", "rg", "Rust", "Modern version of grep")
tools_table.add_row("tox", "", "Python", "Tool / Environment orchestration")
tools_table.add_row("rich-cli", "rich", "Python", "Syntax highlighting in terminal")
tools_table.add_row("ducktools-pytui", "pytui", "Python", "Experimental Python managing TUI")
tools_table.add_row("harlequin", "", "Python", "SQLite database viewer and editor")
tools_table.add_row("lazygit", "", "Go", "Terminal UI for git")
tools_table.add_row("cloctui", "", "Python/Perl", "Terminal UI for CLOC")

###################
# FUNCTIONS TABLE #
###################

fzf_table = Table(title="Bash Functions")

fzf_table.add_column("Command\n", style="cyan", no_wrap=True)
fzf_table.add_column("Purpose", style="green")

fzf_table.add_row("fcd", "Fuzzy cd into a directory")
fzf_table.add_row("fsh", "Fuzzy shell history")
fzf_table.add_row("fnano", "Fuzzy nano into a file")
fzf_table.add_row("fbat", "Fuzzy batcat into a file")
fzf_table.add_row("rgf", "Ripgrep by filename")
fzf_table.add_row("colortest", "Print a 16-bit gradient to test truecolor support")
fzf_table.add_row("resource", "Re-source the .bashrc file")
fzf_table.add_row("tkhelp", "Display this help message")

###################
# WELCOME MESSAGE #
###################

console.print(f"\n[cyan]{banner}[/cyan]")
console.print(welcome_message)
console.print(tools_table)
console.print("[italic]Command is same as name if blank[/italic] \n")
console.print(fzf_table)
console.print("\n[italic]Remember to 'tmux a'[/italic] \n")
from rich.console import Console
from rich.table import Table
from pyfiglet import figlet_format

console = Console()

banner = figlet_format("Python Toolkit", font="smslant")

welcome_message = f"""{'=' * 30}
[green]Python Toolkit Container[/green]
           by Edward Jazzhands

OS Base: [cyan]Debian Slim[/cyan]
Container Version: [cyan]0.1[/cyan]
{'=' * 30}"""

### Tools table
tools_table = Table(title="Included CLI and TUI Tools")

tools_table.add_column("Name", style="cyan", no_wrap=True)
tools_table.add_column("Command\n", style="cyan", no_wrap=True)
tools_table.add_column("Written in", style="magenta", no_wrap=True)
tools_table.add_column("Purpose", style="green")

## ! CHANGE THIS TO APP LIST TXT

tools_table.add_row("git", "", "C", "Version Control")
tools_table.add_row("curl", "", "C", "Mostly installing things")
tools_table.add_row("uv", "", "Rust", "Manages all things python")
tools_table.add_row("nvm", "", "Shell", "Node Version Manager for Javascript")
tools_table.add_row("node", "", "C++", "Javascript runtime")
tools_table.add_row("tmux", "", "C", "Screen multiplexer")
tools_table.add_row("make", "", "C", "Build automation")
tools_table.add_row("just", "", "Rust", "Command runner - replaces Make")
tools_table.add_row("gulp", "", "Javascript", "Command runner for JS stuff")
tools_table.add_row("neovim", "", "C", "Terminal text editor")
tools_table.add_row("bat", "", "Rust", "cat with color")
tools_table.add_row("fzf", "", "Go", "fuzzy finder")
tools_table.add_row("ripgrep", "rg", "Rust", "modern version of grep")
tools_table.add_row("black", "", "Python", "formatting")
tools_table.add_row("rich-cli", "rich", "Python", "Syntax highlighting in terminal")
tools_table.add_row("neovim", "nvim", "C", "Terminal-based text/code editor")
tools_table.add_row("ducktools-pytui", "pytui", "Python", "Experimental Python managing TUI")
tools_table.add_row("harlequin", "", "Python", "SQLite database viewer and editor")


console.print(f"\n[cyan]{banner}[/cyan]")
console.print(welcome_message)
console.print(tools_table)
console.print("[italic]Command is same as name if blank[/italic]")
console.print("\nType [cyan]tkhelp[/cyan] (Tool-Kit help) to display this message again.\n")
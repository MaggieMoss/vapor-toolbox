import Console

public final class Fetch: Command {
    public let id = "fetch"

    public let signature: [Argument] = [
        Option(name: "clean", help: ["Cleans the project before fetching."])
    ]

    public let help: [String] = [
        "Fetches the application's dependencies."
    ]

    public let console: Console

    public init(console: Console) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        if arguments.options["clean"]?.bool == true {
            let clean = Clean(console: console)
            try clean.run(arguments: arguments)
        }

        do {
            let ls = try console.subexecute("ls .")
            if !ls.contains("Packages") {
                console.warning("No Packages folder, fetch may take a while...")
            }
        } catch ConsoleError.subexecute(_) {
            // do nothing
        }

        let depBar = console.loadingBar(title: "Fetching Dependencies")
        depBar.start()

        do {
            _ = try console.subexecute("swift package fetch")
            depBar.finish()
        } catch ConsoleError.subexecute(_, let message) {
            depBar.fail()
            if message.contains("dependency graph could not be satisfied because an update") {
                console.info("Try cleaning your project first.")
            } else if message.contains("The dependency graph could not be satisfied") {
                console.info("Check your dependencies' Package.swift files to see where the conflict is.")
            }
            throw Error.general(message.trim())
        }
    }
    
}

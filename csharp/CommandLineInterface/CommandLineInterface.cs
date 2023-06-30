// <copyright file="CommandLineInterface.cs" company="Jason Wohlgemuth">
// Copyright (c) 2023 Jason Wohlgemuth. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>

namespace Prelude {
    using Spectre.Console;

    public class CommandLineInterface {
        public CommandLineInterface() {}

        public static void Menu(string[] values, int limit = 10, string instructions = "[grey](Press [blue]<space>[/] to toggle, [green]<enter>[/] to accept)[/]") {
            var moreChoicesText = values.Length > limit ? "[grey](Move up and down to reveal more items)[/]" : "";
            var items = AnsiConsole.Prompt(
                new MultiSelectionPrompt<string>()
                    .NotRequired()
                    .PageSize(limit)
                    .MoreChoicesText(moreChoicesText)
                    .InstructionsText(instructions)
                    .AddChoices(values));
            foreach (string item in items) {
                AnsiConsole.WriteLine(item);
            }
        }

        public static void HelloWorld() {
            AnsiConsole.Markup("[yellow bold underline]Hello[/] World");
            // Ask for the user's favorite fruits
            var fruits = AnsiConsole.Prompt(
                new MultiSelectionPrompt<string>()
                    .Title("What are your [green]favorite fruits[/]?")
                    .NotRequired() // Not required to have a favorite fruit
                    .PageSize(10)
                    .MoreChoicesText("[grey](Move up and down to reveal more fruits)[/]")
                    .InstructionsText(
                        "[grey](Press [blue]<space>[/] to toggle a fruit, " +
                        "[green]<enter>[/] to accept)[/]")
                    .AddChoices(new[] {
                        "Apple", "Apricot", "Avocado",
                        "Banana", "Blackcurrant", "Blueberry",
                        "Cherry", "Cloudberry", "Coconut",
                    }));

            // Write the selected fruits to the terminal
            foreach (string fruit in fruits) {
                AnsiConsole.WriteLine(fruit);
            }

        }
    }
}
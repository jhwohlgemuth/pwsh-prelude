// <copyright file="CommandLineInterface.cs" company="Jason Wohlgemuth">
// Copyright (c) 2023 Jason Wohlgemuth. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>

namespace Prelude {
    using Spectre.Console;
    using System.Collections.Generic;

    public class CommandLineInterface {
#nullable enable
        public CommandLineInterface() { }

        public const int COLOR_BLUE = 12;
        public const string DEFAULT_MORE_CHOICES_TEXT = "[grey](Move up and down to reveal more items)[/]";

        public static Style MenuStyle(Color? foreground = null, Color? background = null, Decoration? decoration = null, string link = "") {
            return new Style(foreground, background, decoration, link);
        }

        public static List<string> Menu(string[] values, int limit = 10, Style? style = null, string instructions = "[grey](Press [blue]<space>[/] to toggle, [green]<enter>[/] to accept)[/]") {
            var moreChoicesText = values.Length > limit ? DEFAULT_MORE_CHOICES_TEXT : "";
            var items = AnsiConsole.Prompt(
                new MultiSelectionPrompt<string>()
                    .NotRequired()
                    .PageSize(limit)
                    .HighlightStyle(style != null ? style : MenuStyle(COLOR_BLUE))
                    .MoreChoicesText(moreChoicesText)
                    .InstructionsText(instructions)
                    .AddChoices(values));
            return items;
        }
        public static string Select(string[] values, int limit = 10, Style? style = null) {
            var moreChoicesText = values.Length > limit ? DEFAULT_MORE_CHOICES_TEXT : "";
            var item = AnsiConsole.Prompt(
                new SelectionPrompt<string>()
                    .PageSize(limit)
                    .HighlightStyle(style != null ? style : MenuStyle(COLOR_BLUE))
                    .MoreChoicesText(moreChoicesText)
                    .AddChoices(values));
            return item;
        }

        public static void HelloWorld() {
            AnsiConsole.Markup("[yellow bold underline]Hello[/] World");
        }
    }
}
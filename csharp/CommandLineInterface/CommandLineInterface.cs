// <copyright file="CommandLineInterface.cs" company="Jason Wohlgemuth">
// Copyright (c) 2023 Jason Wohlgemuth. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>

namespace Prelude {
    using Spectre.Console;

    public class CommandLineInterface {
        public CommandLineInterface() {}

        public static void HelloWorld() {
            AnsiConsole.Markup("[yellow bold underline]Hello[/] World");
        }
    }
}
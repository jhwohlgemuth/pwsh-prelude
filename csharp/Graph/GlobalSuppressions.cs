// <copyright file="GlobalSuppressions.cs" company="Jason Wohlgemuth">
// Copyright (c) 2022 Jason Wohlgemuth. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>

using System.Diagnostics.CodeAnalysis;

[assembly: SuppressMessage("StyleCop.CSharp.LayoutRules", "SA1500:Braces for multi-line statements should not share line", Justification = "1TBS is my favorite")]
[assembly: SuppressMessage("StyleCop.CSharp.ReadabilityRules", "SA1101:Prefix local calls with this", Justification = "Adding a this for local calls is unnecessary")]
[assembly: SuppressMessage("StyleCop.CSharp.ReadabilityRules", "SA1128:Put constructor initializers on their own line", Justification = "I don't like having to do this")]
[assembly: SuppressMessage("StyleCop.CSharp.LayoutRules", "SA1503:Braces should not be omitted", Justification = "I just like the simplicity of being able to omit the braces")]
[assembly: SuppressMessage("StyleCop.CSharp.LayoutRules", "SA1519:Braces should not be omitted from multi-line child statement", Justification = "I just like the simplicity of being able to omit the braces")]
[assembly: SuppressMessage("StyleCop.CSharp.SpacingRules", "SA1000:Keywords should be spaced correctly", Justification = "I kind of prefer a space after the new keyword, but I cannot figure out how to disable the rule")]

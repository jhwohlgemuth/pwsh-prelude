function New-WebApplication {
    <#
    .SYNOPSIS
    Create a new web application.
    .DESCRIPTION
    This function allows you to scaffold a bespoke web application and optionally install dependencies.

    When -NoInstall is not used, dependencies will be installed using npm.

    Before dependencies are installed, application state will be saved using Save-State under the passed application name (or the default, "webapp")

    Application data can be viewed and used using "Get-State <Name>"

    .PARAMETER Name
    Name of application folder
    .PARAMETER Parent
    Parent directory in which to create the application directory
    .EXAMPLE
    New-WebApplication
    .EXAMPLE
    New-WebApplication -Bundler Parcel -Library React -With Cesium
    .EXAMPLE
    New-WebApplication -Parcel -React -With Cesium
    .EXAMPLE
    @{
        Bundler = 'Parcel'
        Library = 'React'
        With = 'Cesium'
    } | New-WebApplication -Name 'My-App'
    #>
    [CmdletBinding(DefaultParameterSetName = 'parameter', SupportsShouldProcess = $True)]
    Param(
        [Parameter(ParameterSetName = 'pipeline', ValueFromPipeline = $True)]
        [PSObject] $Configuration = @{},
        [ApplicationState] $State = @{ Type = 'Web' },
        [Parameter(Position = 0, ParameterSetName = 'parameter')]
        [ValidateSet('Parcel', 'Snowpack', 'Turbopack', 'Vite', 'Webpack')]
        [String] $Bundler,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Webpack,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Parcel,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Snowpack,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Turbopack,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Vite,
        [Parameter(Position = 1, ParameterSetName = 'parameter')]
        [AllowNull()]
        [AllowEmptyString()]
        [ValidateSet('', 'Vanilla', 'React', 'Solid')]
        [String] $Library,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Vanilla,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $React,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Solid,
        [ValidateSet('Cesium', 'Reason', 'Rust')]
        [String[]] $With,
        [String] $Name = 'webapp',
        [ValidateScript( { Test-Path $_ })]
        [String] $Parent = (Get-Location).Path,
        [Parameter(ParameterSetName = 'interactive')]
        [Switch] $Interactive,
        [Switch] $NoInstall,
        [Switch] $Silent,
        [Switch] $Force
    )
    Begin {
        $BundlerOptions = @(
            'Webpack'
            'Parcel'
            'Snowpack'
            'Turbopack'
            'Vite'
        )
        $LibraryOptions = @(
            'Vanilla'
            'React'
            'Solid'
        )
        $WithOptions = @(
            'Cesium'
            'Reason'
            'Rust'
        )
        $Defaults = @{
            Bundler = 'Webpack'
            Library = 'Vanilla'
            With = @()
            SourceDirectory = 'src'
            AssetsDirectory = 'public'
            ProductionDirectory = 'dist'
            RustDirectory = 'rust-to-wasm'
            Legacy = $False
            ReactVersion = '^17'
            License = 'MIT'
        }
    }
    Process {
        $Data = if ($PsCmdlet.ParameterSetName -eq 'pipeline') {
            $Defaults, $Configuration | Invoke-ObjectMerge -Force
        } else {
            if ($Interactive) {
                'Build a Web Application' | Write-Title -Blue -TextColor White -SubText 'choose wisely'
                '' | Write-Label -NewLine

                'Choose your {{#cyan bundler}}:' | Write-Label -Color 'Gray' -NewLine
                $Bundler = Invoke-Menu $BundlerOptions -SingleSelect -SelectedMarker ' => ' -HighlightColor 'Cyan'
                '' | Write-Label -NewLine

                'Choose your {{#yellow library}}:' | Write-Label -Color 'Gray' -NewLine
                $Library = Invoke-Menu $LibraryOptions -SingleSelect -SelectedMarker ' => ' -HighlightColor 'Yellow'
                '' | Write-Label -NewLine

                'Enhance your application {{#magenta with}}:' | Write-Label -Color 'Gray' -NewLine
                $With = Invoke-Menu $WithOptions -MultiSelect -SelectedMarker ' => ' -HighlightColor 'Magenta'
                '' | Write-Label -NewLine
            } else {
                if (-not $Bundler) {
                    $Bundler = Find-FirstTrueVariable $BundlerOptions
                }
                if (-not $Library) {
                    $Library = Find-FirstTrueVariable $LibraryOptions
                }
            }
            $Defaults, @{
                Bundler = $Bundler
                Library = $Library
                With = $With
            } | Invoke-ObjectMerge -Force
        }
        $Data.Name = if ($Data.Name) { $Data.Name } else { $Name }
        $Data.Parent = if ($Data.Parent) { $Data.Parent } else { $Parent }
        $ApplicationDirectory = Join-Path $Data.Parent $Data.Name
        $TemplateDirectory = Join-Path $PSScriptRoot '../src/templates'
        $RustDirectory = Join-Path $ApplicationDirectory $Data.RustDirectory
        $PackageManifestData = @{
            name = $Data.Name
            version = '0.0.0'
            description = ''
            license = $Data.License
            keywords = @()
            main = "./$($Data.SourceDirectory)/main.js$(if ($Library -eq 'React') { 'x' })"
            scripts = @{}
            dependencies = @{}
            devDependencies = @{}
        }
        $ConfigurationFileData = @{
            Reason = @{
                'name' = $Data.Name
                'bs-dependencies' = @(
                    '@rescript/react'
                )
                'bsc-flags' = @(
                    '-bs-super-errors'
                )
                'namespace' = $True
                'package-specs' = @(
                    @{
                        'module' = 'es6'
                        'in-source' = $True
                    }
                )
                'ppx-flags' = @()
                'reason' = @{
                    'react-jsx' = 3
                }
                'refmt' = 3
                'sources' = @(
                    @{
                        'dir' = $Data.SourceDirectory
                        'subdirs' = $True
                    }
                )
                'suffix' = '.bs.js'
            }
            Webpack = @{
                SourceDirectory = $Data.SourceDirectory
                AssetsDirectory = $Data.AssetsDirectory
                ProductionDirectory = $Data.ProductionDirectory
                UseReact = ($Library -eq 'React')
                WithCesium = ($With -contains 'Cesium')
                WithRust = ($With -contains 'Rust')
                CesiumConfig = ("
                    new DefinePlugin({CESIUM_BASE_URL: JSON.stringify('/')}),
                    new CopyWebpackPlugin({
                        patterns: [
                            {from: join(source, 'Workers'), to: 'Workers'},
                            {from: join(source, 'ThirdParty'), to: 'ThirdParty'},
                            {from: join(source, 'Assets'), to: 'Assets'},
                            {from: join(source, 'Widgets'), to: 'Widgets'}
                        ]
                    })" | Remove-Indent -Size 12)
            }
        }
        $Dependencies = @{
            Cesium = @{
                'cesium' = '^1.93.0'
            }
            React = @{
                Core = @{
                    'prop-types' = '*'
                    'react' = $Data.ReactVersion
                    'react-dom' = $Data.ReactVersion
                    'wouter' = '*'
                }
                Cesium = @{
                    'resium' = '^1.14.3'
                }
            }
            Reason = @{
                '@rescript/react' = '*'
            }
            Solid = @{}
        }
        $DevelopmentDependencies = @{
            _workflow = @{
                'cpy-cli' = '*'
                'del-cli' = '*'
                'npm-run-all' = '*'
                'watch' = '*'
            }
            Cesium = @{}
            Parcel = @{
                'parcel' = '*'
                'parcel-plugin-purgecss' = '*'
            }
            Postcss = @{
                Core = @{
                    'cssnano' = '^5.1.9'
                    'postcss' = '^8.4.14'
                    'postcss-cli' = '^9.1.0'
                    'postcss-import' = '^14.1.0'
                    'postcss-preset-env' = '^7.6.0'
                    'postcss-reporter' = '^7.0.5'
                    'postcss-safe-parser' = '^6.0.0'
                }
                React = @{}
            }
            React = @{
                '@hot-loader/react-dom' = $Data.ReactVersion
                'react-hot-loader' = '*'
            }
            Reason = @{
                'rescript' = '*'
            }
            Rust = @{
                '@wasm-tool/wasm-pack-plugin' = '*'
            }
            Stylelint = @{
                'stylelint' = '^14.8.3'
                'stylelint-config-recommended' = '^7.0.0'
            }
            Snowpack = @{
                'snowpack' = '*'
                '@snowpack/app-scripts-react' = '*'
                '@snowpack/plugin-react-refresh' = '*'
                '@snowpack/plugin-postcss' = '*'
                '@snowpack/plugin-optimize' = '*'
            }
            Webpack = @{
                'webpack' = '*'
                'webpack-bundle-analyzer' = '*'
                'webpack-cli' = '*'
                'webpack-dashboard' = '*'
                'webpack-dev-server' = '*'
                'webpack-jarvis' = '*'
                'webpack-subresource-integrity' = '*'
                'babel-loader' = '*'
                'css-loader' = '*'
                'file-loader' = '*'
                'style-loader' = '*'
                'url-loader' = '*'
                'copy-webpack-plugin' = '*'
                'html-webpack-plugin' = '*'
                'terser-webpack-plugin' = '*'
            }
        }
        $NpmScripts = @{
            Common = @{
                Core = @{}
                React = @{}
            }
            Parcel = @{
                Core = @{}
                React = @{}
            }
            Snowpack = @{
                Core = @{}
                React = @{}
            }
            TurboPack = @{
                Core = @{}
                React = @{}
            }
            Webpack = @{
                Core = @{
                    'start' = ''
                    'clean' = "del-cli $($Data.ProductionDirectory)"
                    'copy' = 'npm-run-all --parallel copy:assets'
                    'copy:assets' = "cpy \`"$($Data.AssetsDirectory)/!(css)/**/*.*\`" \`"$($Data.AssetsDirectory)/**/[.]*\`" $($Data.ProductionDirectory) --parents --recursive"
                    'prebuild:es' = "del-cli $($Data.ProductionDirectory)/$($Data.AssetsDirectory)"
                    'build:es' = 'webpack'
                    'build:stats' = 'webpack --mode production --profile --json > stats.json'
                    'build:analyze' = 'webpack-bundle-analyzer ./stats.json'
                    'postbuild:es' = 'npm run copy'
                    'watch:assets' = "watch \`"npm run copy\`" $($Data.AssetsDirectory)"
                    'watch:es' = "watch \`"npm run build:es\`" $($Data.AssetsDirectory)"
                    'dashboard' = 'webpack-dashboard -- webpack serve --config ./webpack.config.js'
                    'predeploy' = 'npm-run-all clean "build:es -- --mode=production" build:css'
                    'deploy' = 'echo \"Not yet implemented - now.sh or surge.sh are supported out of the box\" && exit 1'
                }
                React = @{}
            }
        }
        if ($PSCmdlet.ShouldProcess('Create application folder structure and common assets')) {
            $Source = $Data.SourceDirectory
            $Assets = $Data.AssetsDirectory
            @(
                ''
                $Source
                "${Source}/components"
                $Assets
                "${Assets}/css"
                "${Assets}/fonts"
                "${Assets}/images"
                "${Assets}/library"
                "${Assets}/workers"
                '__tests__'
            ) | ForEach-Object { New-Item -Type Directory -Path (Join-Path $ApplicationDirectory $_) -Force } | Out-Null
        }
        if ($PSCmdlet.ShouldProcess('Copy common assets')) {
            $Data, @{
                UseReact = ($Library -eq 'React')
                WithCesium = ($With -contains 'Cesium')
                NoJavaScriptEnglish = 'Please enable JavaScript in your browser for a better experience.'
                NoJavaScriptFrench = 'Veuillez activer JavaScript dans votre navigateur pour une meilleure expérience.'
                NoJavaScriptJapanese = 'より良い体験のため、ブラウザでJavaScriptを有効にして下さい'
                NoJavaScriptChinese = '请在你的浏览器中启用JavaScript以便享受最佳体验'
            } | Invoke-ObjectMerge -InPlace -Force
            $Assets = Join-Path $ApplicationDirectory $Data.AssetsDirectory
            @(
                @{
                    Filename = 'index.html'
                    Template = 'source/html_index'
                    Parent = $Assets
                }
                @{
                    Filename = 'style.css'
                    Template = 'source/css_style'
                    Parent = (Join-Path $Assets 'css')
                }
                @{
                    Filename = '.gitkeep'
                    Template = 'gitkeep'
                    Parent = (Join-Path $Assets 'fonts')
                }
                @{
                    Filename = '.gitkeep'
                    Template = 'gitkeep'
                    Parent = (Join-Path $Assets 'images')
                }
                @{
                    Filename = '.gitkeep'
                    Template = 'gitkeep'
                    Parent = (Join-Path $Assets 'library')
                }
                @{
                    Filename = '.gitkeep'
                    Template = 'gitkeep'
                    Parent = (Join-Path $Assets 'workers')
                }
            ) | ForEach-Object {
                $Parameters = $_
                $Common = @{
                    Data = $Data
                    Force = $Force
                    TemplateDirectory = $TemplateDirectory
                    Encoding = 'utf8'
                }
                Save-TemplateData @Parameters @Common
            }
        }
        switch ($Bundler) {
            Parcel {
                if ($PSCmdlet.ShouldProcess('Add Parcel dependencies to package.json')) {
                    $PackageManifestData.devDependencies += $DevelopmentDependencies.Parcel
                }
                if ($PSCmdlet.ShouldProcess('Copy Parcel files')) {
                    # TODO: Add code for copying files
                }
            }
            Turbopack {
                if ($PSCmdlet.ShouldProcess('Add Turbopack dependencies to package.json')) {
                    $PackageManifestData.devDependencies += $DevelopmentDependencies.TurboPack
                }
                if ($PSCmdlet.ShouldProcess('Save Turbopack configuration file')) {
                    # TODO: Add code for copying files
                }
            }
            Snowpack {
                if ($PSCmdlet.ShouldProcess('Add Snowpack dependencies to package.json')) {
                    $PackageManifestData.devDependencies += $DevelopmentDependencies.Snowpack
                }
                if ($PSCmdlet.ShouldProcess('Save Snowpack configuration file')) {
                    # TODO: Add code for copying files
                }
            }
            Default {
                if ($PSCmdlet.ShouldProcess('Add Webpack dependencies and tasks to package.json')) {
                    $PackageManifestData.devDependencies += $DevelopmentDependencies._workflow
                    $PackageManifestData.devDependencies += $DevelopmentDependencies.Webpack
                    $PackageManifestData.devDependencies += $DevelopmentDependencies.Stylelint
                    $PackageManifestData.scripts += $NpmScripts.Common.Core
                    $PackageManifestData.scripts += $NpmScripts.Webpack.Core
                }
                if ($PSCmdlet.ShouldProcess('Save Webpack configuration file')) {
                    $Parameters = @{
                        Filename = 'webpack.config.js'
                        Template = 'config/webpack'
                        TemplateDirectory = $TemplateDirectory
                        Data = $ConfigurationFileData.Webpack
                        Parent = $ApplicationDirectory
                        Force = $Force
                    }
                    Save-TemplateData @Parameters
                }
            }
        }
        switch ($Library) {
            React {
                if ($PSCmdlet.ShouldProcess('Add React dependencies to package.json')) {
                    $PackageManifestData.dependencies += $Dependencies.React.Core
                    $PackageManifestData.devDependencies += $DevelopmentDependencies.React
                }
                if ($PSCmdlet.ShouldProcess('Copy React files')) {
                    $Source = Join-Path $ApplicationDirectory 'src'
                    $Components = Join-Path $Source 'components'
                    @(
                        @{
                            Filename = 'main.jsx'
                            Template = 'source/react/main'
                            Parent = $Source
                        }
                        @{
                            Filename = 'App.jsx'
                            Template = 'source/react/app'
                            Parent = $Components
                        }
                        @{
                            Filename = 'Header.jsx'
                            Template = 'source/react/header'
                            Parent = $Components
                        }
                        @{
                            Filename = 'Body.jsx'
                            Template = 'source/react/body'
                            Parent = $Components
                        }
                        @{
                            Filename = 'Footer.jsx'
                            Template = 'source/react/footer'
                            Parent = $Components
                        }
                    ) | ForEach-Object {
                        $Parameters = $_
                        $Common = @{
                            Data = $Data
                            Force = $Force
                            TemplateDirectory = $TemplateDirectory
                        }
                        Save-TemplateData @Parameters @Common
                    }
                }
            }
            Solid {
                if ($PSCmdlet.ShouldProcess('Add Solid dependencies to package.json')) {
                    $PackageManifestData.dependencies += $Dependencies.Solid
                }
                if ($PSCmdlet.ShouldProcess('Copy Solid files')) {
                    # TODO: Add code for copying files
                }
            }
            Default {
                if ($PSCmdlet.ShouldProcess('Copy JavaScript files')) {
                    $Source = Join-Path $ApplicationDirectory 'src'
                    $Parameters = @{
                        Filename = 'main.js'
                        Template = 'source/vanilla_main'
                        TemplateDirectory = $TemplateDirectory
                        Data = $Data
                        Parent = $Source
                        Force = $Force
                    }
                    Save-TemplateData @Parameters
                }
            }
        }
        switch ($With) {
            Cesium {
                if ($PSCmdlet.ShouldProcess('Add Cesium dependencies to package.json')) {
                    $PackageManifestData.dependencies += $Dependencies.Cesium
                    if ($Library -eq 'React') {
                        $PackageManifestData.dependencies += $Dependencies.React.Cesium
                    }
                    $PackageManifestData.devDependencies += $DevelopmentDependencies.Cesium
                }
            }
            Reason {
                if ($Library -ne 'React' -and (-not $Silent)) {
                    '==> ReasonML works best with React.  You might consider using -React.' | Write-Warning
                }
                if ($PSCmdlet.ShouldProcess('Add ReasonML dependencies to package.json')) {
                    $PackageManifestData.dependencies += $Dependencies.Reason
                    $PackageManifestData.devDependencies += $DevelopmentDependencies.Reason
                }
                if ($PSCmdlet.ShouldProcess('Save ReasonML configuration file; Add dependencies to package.json')) {
                    $Parameters = @{
                        Filename = 'bsconfig.json'
                        Data = $ConfigurationFileData.Reason
                        Parent = $ApplicationDirectory
                        Force = $Force
                    }
                    Save-JsonData @Parameters
                }
                if ($PSCmdlet.ShouldProcess('Copy ReasonML files')) {
                    $Components = Join-Path $ApplicationDirectory 'src/components'
                    @(
                        @{
                            Filename = 'App.re'
                            Template = 'source/reason/app'
                        }
                        @{
                            Filename = 'Example.re'
                            Template = 'source/reason/example'
                        }
                    ) | ForEach-Object {
                        $Parameters = $_
                        $Common = @{
                            Data = $Data
                            Parent = $Components
                            Force = $Force
                            TemplateDirectory = $TemplateDirectory
                        }
                        Save-TemplateData @Parameters @Common
                    }
                }
            }
            Rust {
                if ($PSCmdlet.ShouldProcess('Add Rust dependencies to package.json')) {
                    $PackageManifestData.devDependencies += $DevelopmentDependencies.Rust
                }
                if ($PSCmdlet.ShouldProcess('Copy Rust files')) {
                    $Source = Join-Path $RustDirectory 'src'
                    $Tests = Join-Path $RustDirectory 'tests'
                    @(
                        $RustDirectory
                        $Source
                        $Tests
                    ) | Get-StringPath | ForEach-Object { New-Item -Type Directory -Path $_ -Force } | Out-Null
                    @(
                        @{
                            Filename = 'Cargo.toml'
                            Template = 'config/rust'
                            Parent = $ApplicationDirectory
                        }
                        @{
                            Filename = 'Cargo.toml'
                            Template = 'config/crate'
                            Parent = $RustDirectory
                        }
                        @{
                            Filename = 'lib.rs'
                            Template = 'source/rust/lib'
                            Parent = $Source
                        }
                        @{
                            Filename = 'utils.rs'
                            Template = 'source/rust/utils'
                            Parent = $Source
                        }
                        @{
                            Filename = 'app.rs'
                            Template = 'source/rust/app'
                            Parent = $Tests
                        }
                        @{
                            Filename = 'web.rs'
                            Template = 'source/rust/web'
                            Parent = $Tests
                        }
                    ) | ForEach-Object {
                        $Parameters = $_
                        $Common = @{
                            Data = $Data
                            Force = $Force
                            TemplateDirectory = $TemplateDirectory
                        }
                        Save-TemplateData @Parameters @Common
                    }
                }
            }
            Default {}
        }
        if ($PSCmdlet.ShouldProcess('Save EditorConfig configuration file')) {
            $Parameters = @{
                Filename = '.editorconfig'
                Template = 'config/editor'
                TemplateDirectory = $TemplateDirectory
                Data = @{}
                Parent = $ApplicationDirectory
                Force = $Force
            }
            Save-TemplateData @Parameters
        }
        if ($PSCmdlet.ShouldProcess('Save package.json to application directory')) {
            $PackageManifestData = $PackageManifestData | ConvertTo-OrderedDictionary
            $PackageManifestData.dependencies = $PackageManifestData.dependencies | ConvertTo-OrderedDictionary
            $PackageManifestData.devDependencies = $PackageManifestData.devDependencies | ConvertTo-OrderedDictionary
            $PackageManifestData.scripts = $PackageManifestData.scripts | ConvertTo-OrderedDictionary
            $Parameters = @{
                Filename = 'package.json'
                Data = $PackageManifestData
                Parent = $ApplicationDirectory
                Force = $Force
            }
            Save-JsonData @Parameters
        }
        $Context = if ($PSCmdlet.ShouldProcess('Test application context')) {
            Test-ApplicationContext $ApplicationDirectory
        } else {
            Test-ApplicationContext
        }
        $Data, @{
            Context = $Context
            PackageManifestData = $PackageManifestData
        } | Invoke-ObjectMerge -Force -InPlace
        $State, @{
            Data = $Data
            Name = $Data.Name
            Parent = $Data.Parent
        } | Invoke-ObjectMerge -Force -InPlace
        $Tools = @(
            'Babel'
            'ESLint'
            'PostCSS'
            'Jest'
        )
        if ($PSCmdlet.ShouldProcess("Add development tools - $($Tools | Join-StringsWithGrammar)")) {
            Update-Application -Add $Tools -Parent $ApplicationDirectory -State $State
        }
    }
    End {
        if ($PSCmdlet.ShouldProcess('Save application state')) {
            $State | Save-State -Name $State.Name -Verbose:(-not $Silent) -Force:$Force | Out-Null
        }
        if (-not $NoInstall) {
            if ($PSCmdlet.ShouldProcess('Install dependencies')) {
                $NoErrors = if ($Context.Node.Ready) {
                    $Parameters = @{
                        Parent = $ApplicationDirectory
                        Silent = $Silent
                    }
                    Invoke-NpmInstall @Parameters
                }
            }
            if (($NoErrors -and (-not $Silent)) -or $Interactive) {
                'done' | Write-Status
            }
        }
    }
}
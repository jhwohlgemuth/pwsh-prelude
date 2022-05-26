module.exports = {
    map: true,
    parser: require('postcss-safe-parser'),
    plugins: [
        require('stylelint')({config: {extends: 'stylelint-config-recommended'}}),
        require('postcss-import')(),
        require('postcss-preset-env')({stage: 0}),
        require('cssnano')(),
        require('postcss-reporter')({clearReportedMessages: true})
    ]
};
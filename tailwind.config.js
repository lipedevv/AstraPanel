const colors = require('tailwindcss/colors');

const gray = {
    50: '#f7f9fc',
    100: '#e8edf5',
    200: '#cdd6e5',
    300: '#aab7cb',
    400: '#7f8da6',
    500: '#596981',
    600: '#394860',
    700: '#202c40',
    800: '#111a2b',
    900: '#080d18',
};

const astra = {
    50: '#effcff',
    100: '#cff8fe',
    200: '#a5effc',
    300: '#67e3f7',
    400: '#22d3ee',
    500: '#06b6d4',
    600: '#0891b2',
    700: '#0e7490',
    800: '#155e75',
    900: '#164e63',
};

module.exports = {
    content: ['./resources/scripts/**/*.{js,ts,tsx}'],
    theme: {
        extend: {
            fontFamily: {
                header: ['"IBM Plex Sans"', '"Roboto"', 'system-ui', 'sans-serif'],
            },
            colors: {
                black: '#131a20',
                // "primary" and "neutral" are deprecated, prefer the use of "blue" and "gray"
                // in new code.
                primary: astra,
                blue: astra,
                gray: gray,
                neutral: gray,
                cyan: colors.cyan,
            },
            fontSize: {
                '2xs': '0.625rem',
            },
            transitionDuration: {
                250: '250ms',
            },
            borderColor: (theme) => ({
                default: theme('colors.neutral.400', 'currentColor'),
            }),
        },
    },
    plugins: [
        require('@tailwindcss/line-clamp'),
        require('@tailwindcss/forms')({
            strategy: 'class',
        }),
    ],
};

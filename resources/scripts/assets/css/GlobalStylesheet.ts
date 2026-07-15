import tw from 'twin.macro';
import { createGlobalStyle } from 'styled-components/macro';
// @ts-expect-error untyped font file
import font from '@fontsource-variable/ibm-plex-sans/files/ibm-plex-sans-latin-wght-normal.woff2';

export default createGlobalStyle`
    @font-face {
        font-family: 'IBM Plex Sans';
        font-style: normal;
        font-display: swap;
        font-weight: 100 700;
        src: url(${font}) format('woff2-variations');
        unicode-range: U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD;
    }

    body {
        ${tw`font-sans bg-neutral-900 text-neutral-200`};
        letter-spacing: 0.008em;
        min-height: 100vh;
        background-color: #070b14;
        background-image:
            radial-gradient(circle at 78% -10%, rgba(168, 85, 247, 0.16), transparent 30rem),
            radial-gradient(circle at 22% 8%, rgba(34, 211, 238, 0.12), transparent 28rem),
            linear-gradient(180deg, #080d18 0%, #070b14 45%, #060912 100%);
        background-attachment: fixed;
    }

    body::before {
        content: '';
        position: fixed;
        inset: 0;
        pointer-events: none;
        opacity: 0.24;
        background-image: linear-gradient(rgba(255,255,255,.018) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,.018) 1px, transparent 1px);
        background-size: 36px 36px;
        mask-image: linear-gradient(to bottom, black, transparent 72%);
        z-index: -1;
    }

    ::selection {
        color: #ecfeff;
        background: rgba(8, 145, 178, 0.7);
    }

    h1, h2, h3, h4, h5, h6 {
        ${tw`font-medium tracking-normal font-header`};
        letter-spacing: -0.02em;
    }

    p {
        ${tw`text-neutral-200 leading-snug font-sans`};
    }

    form {
        ${tw`m-0`};
    }

    textarea, select, input, button, button:focus, button:focus-visible {
        ${tw`outline-none`};
    }

    button, a {
        -webkit-tap-highlight-color: transparent;
    }

    .astra-sidebar {
        ${tw`fixed inset-y-0 left-0 z-50 flex w-72 flex-col border-r border-white/5 transition-transform duration-250 lg:sticky lg:top-0 lg:h-screen lg:flex-shrink-0`};
        background: linear-gradient(180deg, rgba(13, 20, 35, 0.98), rgba(7, 11, 20, 0.98));
        box-shadow: 24px 0 70px rgba(0, 0, 0, 0.18);
    }

    .astra-mobile-header {
        ${tw`sticky top-0 z-30 flex h-16 items-center justify-between border-b border-white/5 px-4`};
        background: rgba(8, 13, 24, 0.9);
        backdrop-filter: blur(18px);
    }

    .astra-nav-item {
        ${tw`mb-1 flex items-center gap-3 rounded-xl px-3 py-3 text-sm font-medium text-neutral-400 no-underline transition-all duration-150`};
    }

    .astra-nav-item:hover {
        ${tw`bg-white/5 text-neutral-100`};
        transform: translateX(2px);
    }

    .astra-nav-item.active {
        ${tw`text-cyan-100`};
        background: linear-gradient(90deg, rgba(34, 211, 238, 0.15), rgba(168, 85, 247, 0.08));
        box-shadow: inset 0 0 0 1px rgba(103, 232, 249, 0.12), 0 10px 30px rgba(6, 182, 212, 0.05);
    }

    .astra-nav-icon {
        ${tw`flex h-9 w-9 flex-none items-center justify-center rounded-lg bg-white/5 text-neutral-400 transition`};
    }

    .astra-nav-item.active .astra-nav-icon {
        ${tw`bg-cyan-400/10 text-cyan-300`};
        box-shadow: 0 0 20px rgba(34, 211, 238, 0.12);
    }

    .astra-search-trigger {
        ${tw`flex w-full items-center gap-3 rounded-xl border border-white/5 bg-white/[0.035] px-3 py-3 text-sm text-neutral-500 transition`};
    }

    .astra-search-trigger:hover {
        ${tw`border-cyan-400/20 bg-white/[0.055] text-neutral-300`};
    }

    .astra-search-trigger kbd {
        ${tw`rounded-md border border-white/10 bg-black/20 px-1.5 py-0.5 text-[10px] font-medium text-neutral-500`};
    }

    .astra-panel-card {
        ${tw`rounded-2xl border border-white/[0.07] bg-neutral-800/70`};
        box-shadow: 0 18px 60px rgba(0, 0, 0, 0.18), inset 0 1px rgba(255, 255, 255, 0.025);
        backdrop-filter: blur(12px);
    }

    input[type=number]::-webkit-outer-spin-button,
    input[type=number]::-webkit-inner-spin-button {
        -webkit-appearance: none !important;
        margin: 0;
    }

    input[type=number] {
        -moz-appearance: textfield !important;
    }

    /* Scroll Bar Style */
    ::-webkit-scrollbar {
        background: none;
        width: 12px;
        height: 12px;
    }

    ::-webkit-scrollbar-thumb {
        border: solid 0 rgb(0 0 0 / 0%);
        border-right-width: 3px;
        border-left-width: 3px;
        -webkit-border-radius: 9px 4px;
        -webkit-box-shadow: inset 0 0 0 1px rgba(103, 232, 249, .18), inset 0 0 0 4px rgba(32, 44, 64, .9);
    }

    ::-webkit-scrollbar-track-piece {
        margin: 4px 0;
    }

    ::-webkit-scrollbar-thumb:horizontal {
        border-right-width: 0;
        border-left-width: 0;
        border-top-width: 4px;
        border-bottom-width: 4px;
        -webkit-border-radius: 4px 9px;
    }

    ::-webkit-scrollbar-corner {
        background: transparent;
    }
`;

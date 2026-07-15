import styled from 'styled-components/macro';
import tw from 'twin.macro';

export default styled.div<{ $hoverable?: boolean }>`
    ${tw`flex rounded-xl no-underline text-neutral-200 items-center bg-neutral-800/80 p-4 border border-white/[0.07] transition-all duration-150 overflow-hidden`};
    box-shadow: 0 12px 40px rgba(0, 0, 0, 0.12), inset 0 1px rgba(255, 255, 255, 0.02);

    ${(props) => props.$hoverable !== false && tw`hover:border-cyan-400/20 hover:bg-neutral-800`};

    & .icon {
        ${tw`rounded-xl w-12 h-12 flex flex-none items-center justify-center bg-cyan-400/10 text-cyan-300 p-3`};
    }
`;

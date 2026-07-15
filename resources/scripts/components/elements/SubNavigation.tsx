import styled from 'styled-components/macro';
import tw from 'twin.macro';

const SubNavigation = styled.div`
    ${tw`sticky top-16 lg:top-0 z-30 w-full overflow-x-auto border-b border-white/5`};
    background: rgba(8, 12, 23, 0.82);
    backdrop-filter: blur(18px);

    & > div {
        ${tw`flex items-center text-sm mx-auto px-4 py-3`};
        max-width: 1440px;

        & > a,
        & > div {
            ${tw`inline-flex items-center py-2 px-4 rounded-xl text-neutral-400 no-underline whitespace-nowrap transition-all duration-150`};

            &:not(:first-of-type) {
                ${tw`ml-1`};
            }

            &:hover {
                ${tw`text-neutral-100 bg-white/5`};
            }

            &:active,
            &.active {
                ${tw`text-cyan-200 bg-cyan-400/10`};
                box-shadow: inset 0 0 0 1px rgba(34, 211, 238, 0.18), 0 8px 30px rgba(8, 145, 178, 0.08);
            }
        }
    }
`;

export default SubNavigation;

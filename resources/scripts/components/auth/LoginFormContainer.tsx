import React, { forwardRef } from 'react';
import { Form } from 'formik';
import styled from 'styled-components/macro';
import FlashMessageRender from '@/components/FlashMessageRender';

type Props = React.DetailedHTMLProps<React.FormHTMLAttributes<HTMLFormElement>, HTMLFormElement> & {
    title?: string;
};

const Container = styled.div`
    width: calc(100% - 2rem);
    max-width: 1080px;
    margin: 0 auto;
`;

export default forwardRef<HTMLFormElement, Props>(({ title, ...props }, ref) => (
    <Container>
        <div
            className={
                'overflow-hidden rounded-3xl border border-white/10 bg-white shadow-[0_35px_100px_rgba(0,0,0,.45)] md:grid md:grid-cols-[1.08fr_.92fr]'
            }
        >
            <div
                className={
                    'relative hidden min-h-[600px] overflow-hidden bg-neutral-900 p-10 md:flex md:flex-col md:justify-between'
                }
            >
                <div className={'absolute -left-24 -top-24 h-80 w-80 rounded-full bg-cyan-400/20 blur-3xl'} />
                <div className={'absolute -bottom-24 -right-20 h-96 w-96 rounded-full bg-purple-500/25 blur-3xl'} />
                <div
                    className={
                        'absolute inset-0 opacity-30 [background-image:linear-gradient(rgba(255,255,255,.04)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,.04)_1px,transparent_1px)] [background-size:34px_34px]'
                    }
                />

                <div className={'relative'}>
                    <img src={'/assets/svgs/astra.svg'} alt={'Astra Panel'} className={'w-56'} />
                    <div
                        className={
                            'mt-8 inline-flex items-center gap-2 rounded-full border border-cyan-300/10 bg-cyan-400/10 px-3 py-1.5 text-[10px] font-semibold uppercase tracking-[0.2em] text-cyan-300'
                        }
                    >
                        <span
                            className={'h-1.5 w-1.5 rounded-full bg-cyan-300 shadow-[0_0_10px_rgba(103,232,249,.9)]'}
                        />
                        Infraestrutura conectada
                    </div>
                </div>

                <div className={'relative'}>
                    <h1 className={'max-w-md text-4xl font-semibold leading-tight text-white'}>
                        Controle total.
                        <br />
                        <span className={'bg-gradient-to-r from-cyan-300 to-purple-400 bg-clip-text text-transparent'}>
                            Experiência simples.
                        </span>
                    </h1>
                    <p className={'mt-5 max-w-sm text-sm leading-relaxed text-neutral-400'}>
                        Gerencie servidores, arquivos, backups e recursos em uma interface criada para ser rápida e
                        agradável.
                    </p>
                    <div className={'mt-8 grid grid-cols-3 gap-3'}>
                        {['Tempo real', 'Seguro', 'Responsivo'].map((item) => (
                            <div
                                key={item}
                                className={
                                    'rounded-xl border border-white/[0.07] bg-white/[0.035] px-3 py-3 text-center text-[10px] font-medium uppercase tracking-wider text-neutral-300'
                                }
                            >
                                {item}
                            </div>
                        ))}
                    </div>
                </div>
            </div>

            <Form
                {...props}
                ref={ref}
                className={'flex min-h-[540px] flex-col justify-center bg-white px-7 py-10 sm:px-12 md:min-h-[600px]'}
            >
                <img
                    src={'/assets/svgs/astra.svg'}
                    alt={'Astra Panel'}
                    className={'mx-auto mb-7 block w-44 rounded-xl bg-neutral-900 p-2 md:hidden'}
                />
                {title && <h2 className={'mb-2 text-3xl font-semibold text-neutral-900'}>{title}</h2>}
                <p className={'mb-7 text-sm text-neutral-500'}>Entre com seus dados para acessar o painel.</p>
                <FlashMessageRender className={'mb-4'} />
                <div>{props.children}</div>
            </Form>
        </div>
        <p className={'mt-5 text-center text-xs text-neutral-500'}>
            &copy; 2015 - {new Date().getFullYear()}&nbsp;
            <a
                rel={'noopener nofollow noreferrer'}
                href={'https://github.com/lipedevv/AstraPanel'}
                target={'_blank'}
                className={'no-underline transition hover:text-cyan-300'}
            >
                Astra Panel
            </a>
        </p>
    </Container>
));

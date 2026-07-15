import React, { useEffect, useState } from 'react';
import { Server } from '@/api/server/getServer';
import getServers from '@/api/getServers';
import ServerRow from '@/components/dashboard/ServerRow';
import Spinner from '@/components/elements/Spinner';
import PageContentBlock from '@/components/elements/PageContentBlock';
import useFlash from '@/plugins/useFlash';
import { useStoreState } from 'easy-peasy';
import { usePersistedState } from '@/plugins/usePersistedState';
import Switch from '@/components/elements/Switch';
import tw from 'twin.macro';
import useSWR from 'swr';
import { PaginatedResult } from '@/api/http';
import Pagination from '@/components/elements/Pagination';
import { useLocation } from 'react-router-dom';

export default () => {
    const { search } = useLocation();
    const defaultPage = Number(new URLSearchParams(search).get('page') || '1');

    const [page, setPage] = useState(!isNaN(defaultPage) && defaultPage > 0 ? defaultPage : 1);
    const { clearFlashes, clearAndAddHttpError } = useFlash();
    const uuid = useStoreState((state) => state.user.data!.uuid);
    const username = useStoreState((state) => state.user.data!.username);
    const rootAdmin = useStoreState((state) => state.user.data!.rootAdmin);
    const [showOnlyAdmin, setShowOnlyAdmin] = usePersistedState(`${uuid}:show_all_servers`, false);

    const { data: servers, error } = useSWR<PaginatedResult<Server>>(
        ['/api/client/servers', showOnlyAdmin && rootAdmin, page],
        () => getServers({ page, type: showOnlyAdmin && rootAdmin ? 'admin' : undefined })
    );

    useEffect(() => {
        setPage(1);
    }, [showOnlyAdmin]);

    useEffect(() => {
        if (!servers) return;
        if (servers.pagination.currentPage > 1 && !servers.items.length) {
            setPage(1);
        }
    }, [servers?.pagination.currentPage]);

    useEffect(() => {
        // Don't use react-router to handle changing this part of the URL, otherwise it
        // triggers a needless re-render. We just want to track this in the URL incase the
        // user refreshes the page.
        window.history.replaceState(null, document.title, `/${page <= 1 ? '' : `?page=${page}`}`);
    }, [page]);

    useEffect(() => {
        if (error) clearAndAddHttpError({ key: 'dashboard', error });
        if (!error) clearFlashes('dashboard');
    }, [error]);

    return (
        <PageContentBlock title={'Visão geral | Astra Panel'} showFlashKey={'dashboard'}>
            <section
                className={
                    'relative mb-8 overflow-hidden rounded-3xl border border-white/[0.07] bg-neutral-800/70 px-6 py-7 sm:px-8 sm:py-9'
                }
            >
                <div
                    className={
                        'pointer-events-none absolute -right-20 -top-32 h-72 w-72 rounded-full bg-purple-500/20 blur-3xl'
                    }
                />
                <div
                    className={
                        'pointer-events-none absolute right-24 top-8 h-40 w-40 rounded-full bg-cyan-400/10 blur-3xl'
                    }
                />
                <div className={'relative flex flex-col justify-between gap-7 md:flex-row md:items-end'}>
                    <div>
                        <div
                            className={
                                'mb-4 inline-flex items-center gap-2 rounded-full border border-cyan-300/10 bg-cyan-400/[0.07] px-3 py-1.5 text-[10px] font-semibold uppercase tracking-[0.2em] text-cyan-300'
                            }
                        >
                            <span
                                className={
                                    'h-1.5 w-1.5 rounded-full bg-cyan-300 shadow-[0_0_10px_rgba(103,232,249,.8)]'
                                }
                            />
                            Astra Control Center
                        </div>
                        <h1 className={'text-3xl font-semibold text-white sm:text-4xl'}>
                            Olá,{' '}
                            <span
                                className={'bg-gradient-to-r from-cyan-300 to-purple-400 bg-clip-text text-transparent'}
                            >
                                {username}
                            </span>
                        </h1>
                        <p className={'mt-3 max-w-xl text-sm leading-relaxed text-neutral-400 sm:text-base'}>
                            Gerencie seus servidores, acompanhe recursos e mantenha tudo sob controle em um só lugar.
                        </p>
                    </div>
                    <div
                        className={
                            'flex min-w-[180px] items-center gap-4 rounded-2xl border border-white/[0.07] bg-black/20 px-5 py-4 backdrop-blur'
                        }
                    >
                        <div
                            className={
                                'flex h-11 w-11 items-center justify-center rounded-xl bg-cyan-400/10 text-xl text-cyan-300'
                            }
                        >
                            ◈
                        </div>
                        <div>
                            <p className={'text-2xl font-semibold text-white'}>{servers?.pagination.total || 0}</p>
                            <p className={'text-xs uppercase tracking-wider text-neutral-500'}>Servidores</p>
                        </div>
                    </div>
                </div>
            </section>

            <div className={'mb-5 flex flex-col justify-between gap-3 sm:flex-row sm:items-center'}>
                <div>
                    <h2 className={'text-xl font-semibold text-neutral-100'}>Seus servidores</h2>
                    <p className={'mt-1 text-sm text-neutral-500'}>Status e consumo atualizados automaticamente.</p>
                </div>
                {rootAdmin && (
                    <div
                        className={'flex items-center rounded-xl border border-white/[0.07] bg-white/[0.035] px-3 py-2'}
                    >
                        <p css={tw`uppercase text-2xs tracking-wider text-neutral-400 mr-3`}>
                            {showOnlyAdmin ? 'Servidores de outros usuários' : 'Somente meus servidores'}
                        </p>
                        <Switch
                            name={'show_all_servers'}
                            defaultChecked={showOnlyAdmin}
                            onChange={() => setShowOnlyAdmin((s) => !s)}
                        />
                    </div>
                )}
            </div>
            {!servers ? (
                <div className={'astra-panel-card flex min-h-[260px] items-center justify-center'}>
                    <Spinner centered size={'large'} />
                </div>
            ) : (
                <Pagination data={servers} onPageSelect={setPage}>
                    {({ items }) =>
                        items.length > 0 ? (
                            <div className={'grid gap-4 xl:grid-cols-2'}>
                                {items.map((server) => (
                                    <ServerRow key={server.uuid} server={server} />
                                ))}
                            </div>
                        ) : (
                            <div className={'astra-panel-card px-6 py-16 text-center'}>
                                <p css={tw`text-sm text-neutral-400`}>
                                    {showOnlyAdmin
                                        ? 'Não há outros servidores para exibir.'
                                        : 'Nenhum servidor está associado à sua conta.'}
                                </p>
                            </div>
                        )
                    }
                </Pagination>
            )}
        </PageContentBlock>
    );
};

import * as React from 'react';
import { useEffect, useState } from 'react';
import { Link, NavLink, useLocation } from 'react-router-dom';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faBars, faCogs, faLayerGroup, faSignOutAlt, faTimes, faUserCircle } from '@fortawesome/free-solid-svg-icons';
import { useStoreState } from 'easy-peasy';
import { ApplicationStore } from '@/state';
import SearchContainer from '@/components/dashboard/search/SearchContainer';
import http from '@/api/http';
import SpinnerOverlay from '@/components/elements/SpinnerOverlay';
import Avatar from '@/components/Avatar';

export default () => {
    const location = useLocation();
    const name = useStoreState((state: ApplicationStore) => state.settings.data!.name);
    const user = useStoreState((state: ApplicationStore) => state.user.data!);
    const [isLoggingOut, setIsLoggingOut] = useState(false);
    const [mobileOpen, setMobileOpen] = useState(false);

    useEffect(() => setMobileOpen(false), [location.pathname]);

    const onTriggerLogout = () => {
        setIsLoggingOut(true);
        http.post('/auth/logout').finally(() => {
            // @ts-expect-error this is valid
            window.location = '/';
        });
    };

    const navigation = (
        <>
            <div className={'px-5 pt-5 pb-4'}>
                <Link to={'/'} className={'block no-underline'}>
                    <img src={'/assets/svgs/astra.svg'} alt={name} className={'w-44 h-auto'} />
                </Link>
                <div
                    className={'mt-3 flex items-center gap-2 text-[11px] uppercase tracking-[0.24em] text-neutral-400'}
                >
                    <span className={'h-1.5 w-1.5 rounded-full bg-cyan-400 shadow-[0_0_12px_rgba(34,211,238,.9)]'} />
                    Control center
                </div>
            </div>

            <div className={'px-4'}>
                <SearchContainer />
            </div>

            <nav className={'mt-6 flex-1 px-4'}>
                <p className={'px-3 mb-2 text-[10px] font-semibold uppercase tracking-[0.22em] text-neutral-500'}>
                    Navegação
                </p>
                <NavLink to={'/'} exact className={'astra-nav-item'} activeClassName={'active'}>
                    <span className={'astra-nav-icon'}>
                        <FontAwesomeIcon icon={faLayerGroup} />
                    </span>
                    <span>Visão geral</span>
                </NavLink>
                <NavLink to={'/account'} className={'astra-nav-item'} activeClassName={'active'}>
                    <span className={'astra-nav-icon'}>
                        <FontAwesomeIcon icon={faUserCircle} />
                    </span>
                    <span>Minha conta</span>
                </NavLink>
                {user.rootAdmin && (
                    <a href={'/admin'} rel={'noreferrer'} className={'astra-nav-item'}>
                        <span className={'astra-nav-icon'}>
                            <FontAwesomeIcon icon={faCogs} />
                        </span>
                        <span>Administração</span>
                    </a>
                )}
            </nav>

            <div className={'m-4 mt-6 rounded-2xl border border-white/5 bg-white/[0.035] p-3'}>
                <div className={'flex min-w-0 items-center gap-3'}>
                    <span
                        className={
                            'flex h-10 w-10 flex-none items-center justify-center rounded-xl bg-cyan-400/10 text-cyan-300'
                        }
                    >
                        <span className={'h-5 w-5'}>
                            <Avatar.User />
                        </span>
                    </span>
                    <div className={'min-w-0 flex-1'}>
                        <p className={'truncate text-sm font-semibold text-neutral-100'}>{user.username}</p>
                        <p className={'truncate text-xs text-neutral-500'}>{user.email}</p>
                    </div>
                    <button
                        type={'button'}
                        onClick={onTriggerLogout}
                        title={'Sair'}
                        className={
                            'flex h-9 w-9 items-center justify-center rounded-xl text-neutral-400 transition hover:bg-red-500/10 hover:text-red-300'
                        }
                    >
                        <FontAwesomeIcon icon={faSignOutAlt} />
                    </button>
                </div>
            </div>
        </>
    );

    return (
        <>
            <SpinnerOverlay visible={isLoggingOut} />

            <header className={'astra-mobile-header lg:hidden'}>
                <Link to={'/'} className={'no-underline'}>
                    <img src={'/assets/svgs/astra.svg'} alt={name} className={'w-32 h-auto'} />
                </Link>
                <button
                    type={'button'}
                    onClick={() => setMobileOpen((open) => !open)}
                    className={
                        'flex h-10 w-10 items-center justify-center rounded-xl border border-white/10 bg-white/5 text-neutral-200'
                    }
                    aria-label={mobileOpen ? 'Fechar menu' : 'Abrir menu'}
                >
                    <FontAwesomeIcon icon={mobileOpen ? faTimes : faBars} />
                </button>
            </header>

            {mobileOpen && (
                <button
                    type={'button'}
                    aria-label={'Fechar menu'}
                    className={'fixed inset-0 z-40 bg-black/70 backdrop-blur-sm lg:hidden'}
                    onClick={() => setMobileOpen(false)}
                />
            )}

            <aside className={`astra-sidebar ${mobileOpen ? 'translate-x-0' : '-translate-x-full'} lg:translate-x-0`}>
                {navigation}
            </aside>
        </>
    );
};

import React, { memo } from 'react';
import { ServerContext } from '@/state/server';
import Can from '@/components/elements/Can';
import ServerContentBlock from '@/components/elements/ServerContentBlock';
import isEqual from 'react-fast-compare';
import Spinner from '@/components/elements/Spinner';
import Features from '@feature/Features';
import Console from '@/components/server/console/Console';
import StatGraphs from '@/components/server/console/StatGraphs';
import PowerButtons from '@/components/server/console/PowerButtons';
import ServerDetailsBlock from '@/components/server/console/ServerDetailsBlock';
import { Alert } from '@/components/elements/alert';

export type PowerAction = 'start' | 'stop' | 'restart' | 'kill';

const ServerConsoleContainer = () => {
    const name = ServerContext.useStoreState((state) => state.server.data!.name);
    const description = ServerContext.useStoreState((state) => state.server.data!.description);
    const isInstalling = ServerContext.useStoreState((state) => state.server.isInstalling);
    const isTransferring = ServerContext.useStoreState((state) => state.server.data!.isTransferring);
    const eggFeatures = ServerContext.useStoreState((state) => state.server.data!.eggFeatures, isEqual);
    const isNodeUnderMaintenance = ServerContext.useStoreState((state) => state.server.data!.isNodeUnderMaintenance);

    return (
        <ServerContentBlock title={'Console'}>
            {(isNodeUnderMaintenance || isInstalling || isTransferring) && (
                <Alert type={'warning'} className={'mb-4'}>
                    {isNodeUnderMaintenance
                        ? 'The node of this server is currently under maintenance and all actions are unavailable.'
                        : isInstalling
                        ? 'This server is currently running its installation process and most actions are unavailable.'
                        : 'This server is currently being transferred to another node and all actions are unavailable.'}
                </Alert>
            )}
            <div className={'astra-panel-card relative mb-5 grid grid-cols-4 gap-4 overflow-hidden p-5 sm:p-6'}>
                <div
                    className={
                        'pointer-events-none absolute -right-12 -top-20 h-44 w-44 rounded-full bg-cyan-400/10 blur-3xl'
                    }
                />
                <div className={'relative col-span-4 sm:col-span-2 lg:col-span-3'}>
                    <div
                        className={
                            'mb-2 inline-flex items-center gap-2 text-[10px] font-semibold uppercase tracking-[0.2em] text-cyan-400'
                        }
                    >
                        <span
                            className={'h-1.5 w-1.5 rounded-full bg-cyan-300 shadow-[0_0_10px_rgba(103,232,249,.8)]'}
                        />
                        Servidor conectado
                    </div>
                    <h1
                        className={
                            'font-header font-semibold text-2xl sm:text-3xl text-gray-50 leading-relaxed line-clamp-1'
                        }
                    >
                        {name}
                    </h1>
                    <p className={'mt-1 text-sm text-neutral-400 line-clamp-2'}>
                        {description || 'Gerenciado pelo Astra Panel'}
                    </p>
                </div>
                <div className={'relative col-span-4 sm:col-span-2 lg:col-span-1 self-center'}>
                    <Can action={['control.start', 'control.stop', 'control.restart']} matchAny>
                        <PowerButtons className={'flex sm:justify-end space-x-2'} />
                    </Can>
                </div>
            </div>
            <div className={'grid grid-cols-4 gap-2 sm:gap-4 mb-5'}>
                <div className={'flex col-span-4 lg:col-span-3'}>
                    <Spinner.Suspense>
                        <Console />
                    </Spinner.Suspense>
                </div>
                <ServerDetailsBlock className={'col-span-4 lg:col-span-1 order-last lg:order-none'} />
            </div>
            <div className={'grid grid-cols-1 md:grid-cols-3 gap-2 sm:gap-4'}>
                <Spinner.Suspense>
                    <StatGraphs />
                </Spinner.Suspense>
            </div>
            <Features enabled={eggFeatures} />
        </ServerContentBlock>
    );
};

export default memo(ServerConsoleContainer, isEqual);

import React, { useEffect, useRef, useState } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faEthernet, faHdd, faMemory, faMicrochip, faServer } from '@fortawesome/free-solid-svg-icons';
import { Link } from 'react-router-dom';
import { Server } from '@/api/server/getServer';
import getServerResourceUsage, { ServerStats } from '@/api/server/getServerResourceUsage';
import { bytesToString, ip, mbToBytes } from '@/lib/formatters';
import Spinner from '@/components/elements/Spinner';
import styled from 'styled-components/macro';

const ServerCard = styled(Link)`
    position: relative;
    display: block;
    min-width: 0;
    overflow: hidden;
    border: 1px solid rgba(255, 255, 255, 0.07);
    border-radius: 0.75rem;
    padding: 1.1rem;
    color: inherit;
    text-decoration: none;
    background: rgba(17, 26, 43, 0.78);
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
    transition: transform 180ms ease, border-color 180ms ease, box-shadow 180ms ease;

    &::before {
        content: '';
        position: absolute;
        inset: 0 auto 0 0;
        width: 2px;
        background: #22d3ee;
        opacity: 0.55;
    }

    &:hover {
        transform: translateY(-1px);
        border-color: rgba(103, 232, 249, 0.16);
        box-shadow: 0 12px 28px rgba(0, 0, 0, 0.16);
    }
`;

const isAlarmState = (current: number, limit: number): boolean => limit > 0 && current / (limit * 1024 * 1024) >= 0.9;

const Metric = ({
    icon,
    label,
    value,
    limit,
    alarm,
}: {
    icon: any;
    label: string;
    value: string;
    limit: string;
    alarm: boolean;
}) => (
    <div className={'rounded-xl border border-white/5 bg-black/20 px-3 py-3'}>
        <div className={'mb-2 flex items-center gap-2'}>
            <FontAwesomeIcon icon={icon} className={alarm ? 'text-red-300' : 'text-cyan-400'} />
            <span className={'text-[10px] font-semibold uppercase tracking-wider text-neutral-500'}>{label}</span>
        </div>
        <p className={`truncate text-sm font-semibold ${alarm ? 'text-red-200' : 'text-neutral-100'}`}>{value}</p>
        <p className={'mt-0.5 truncate text-[10px] text-neutral-600'}>de {limit}</p>
    </div>
);

type Timer = ReturnType<typeof setInterval>;

export default ({ server, className }: { server: Server; className?: string }) => {
    const interval = useRef<Timer>(null) as React.MutableRefObject<Timer>;
    const [isSuspended, setIsSuspended] = useState(server.status === 'suspended');
    const [stats, setStats] = useState<ServerStats | null>(null);

    const getStats = () =>
        getServerResourceUsage(server.uuid)
            .then((data) => setStats(data))
            .catch((error) => console.error(error));

    useEffect(() => {
        setIsSuspended(stats?.isSuspended || server.status === 'suspended');
    }, [stats?.isSuspended, server.status]);

    useEffect(() => {
        if (isSuspended || server.isNodeUnderMaintenance) return;

        getStats().then(() => {
            interval.current = setInterval(() => getStats(), 30000);
        });

        return () => {
            interval.current && clearInterval(interval.current);
        };
    }, [isSuspended, server.isNodeUnderMaintenance]);

    const alarms = { cpu: false, memory: false, disk: false };
    if (stats) {
        alarms.cpu = server.limits.cpu !== 0 && stats.cpuUsagePercent >= server.limits.cpu * 0.9;
        alarms.memory = isAlarmState(stats.memoryUsageInBytes, server.limits.memory);
        alarms.disk = server.limits.disk !== 0 && isAlarmState(stats.diskUsageInBytes, server.limits.disk);
    }

    const diskLimit = server.limits.disk !== 0 ? bytesToString(mbToBytes(server.limits.disk)) : 'Ilimitado';
    const memoryLimit = server.limits.memory !== 0 ? bytesToString(mbToBytes(server.limits.memory)) : 'Ilimitado';
    const cpuLimit = server.limits.cpu !== 0 ? `${server.limits.cpu} %` : 'Ilimitado';
    const allocation = server.allocations.find((item) => item.isDefault);

    const status = isSuspended
        ? {
              label: server.status === 'suspended' ? 'Suspenso' : 'Erro de conexão',
              tone: 'bg-red-400',
              text: 'text-red-200',
          }
        : server.isNodeUnderMaintenance
        ? { label: 'Manutenção', tone: 'bg-yellow-300', text: 'text-yellow-200' }
        : stats?.status === 'running'
        ? { label: 'Online', tone: 'bg-green-400', text: 'text-green-200' }
        : stats?.status === 'offline'
        ? { label: 'Offline', tone: 'bg-red-400', text: 'text-red-200' }
        : { label: stats ? 'Iniciando' : 'Conectando', tone: 'bg-yellow-300', text: 'text-yellow-200' };

    return (
        <ServerCard to={`/server/${server.id}`} className={className}>
            <div className={'flex min-w-0 items-start gap-4'}>
                <div
                    className={
                        'flex h-12 w-12 flex-none items-center justify-center rounded-2xl border border-cyan-300/10 bg-gradient-to-br from-cyan-400/15 to-purple-500/10 text-cyan-300'
                    }
                >
                    <FontAwesomeIcon icon={faServer} />
                </div>
                <div className={'min-w-0 flex-1'}>
                    <div className={'flex items-start justify-between gap-3'}>
                        <div className={'min-w-0'}>
                            <h3 className={'truncate text-lg font-semibold text-neutral-100'}>{server.name}</h3>
                            <p className={'mt-1 line-clamp-1 text-xs text-neutral-500'}>
                                {server.description || 'Servidor gerenciado pelo Astra Panel'}
                            </p>
                        </div>
                        <div className={`flex flex-none items-center gap-2 text-xs font-medium ${status.text}`}>
                            <span className={`h-2 w-2 rounded-full ${status.tone} shadow-[0_0_12px_currentColor]`} />
                            {status.label}
                        </div>
                    </div>

                    {allocation && (
                        <div
                            className={
                                'mt-4 inline-flex max-w-full items-center gap-2 rounded-lg border border-white/5 bg-white/[0.025] px-2.5 py-1.5 text-xs text-neutral-400'
                            }
                        >
                            <FontAwesomeIcon icon={faEthernet} className={'text-purple-300'} />
                            <span className={'truncate'}>
                                {allocation.alias || ip(allocation.ip)}:{allocation.port}
                            </span>
                        </div>
                    )}
                </div>
            </div>

            <div className={'mt-5'}>
                {!stats || isSuspended || server.isNodeUnderMaintenance ? (
                    <div
                        className={
                            'flex h-[76px] items-center justify-center rounded-xl border border-white/5 bg-black/15'
                        }
                    >
                        {!stats && !isSuspended && !server.isNodeUnderMaintenance ? (
                            <Spinner size={'small'} />
                        ) : (
                            <p className={'text-xs text-neutral-500'}>
                                As métricas ficam disponíveis quando o servidor estiver online.
                            </p>
                        )}
                    </div>
                ) : (
                    <div className={'grid grid-cols-3 gap-2'}>
                        <Metric
                            icon={faMicrochip}
                            label={'CPU'}
                            value={`${stats.cpuUsagePercent.toFixed(2)} %`}
                            limit={cpuLimit}
                            alarm={alarms.cpu}
                        />
                        <Metric
                            icon={faMemory}
                            label={'Memória'}
                            value={bytesToString(stats.memoryUsageInBytes)}
                            limit={memoryLimit}
                            alarm={alarms.memory}
                        />
                        <Metric
                            icon={faHdd}
                            label={'Disco'}
                            value={bytesToString(stats.diskUsageInBytes)}
                            limit={diskLimit}
                            alarm={alarms.disk}
                        />
                    </div>
                )}
            </div>
        </ServerCard>
    );
};

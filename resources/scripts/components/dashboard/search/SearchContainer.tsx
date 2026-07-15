import React, { useState } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faSearch } from '@fortawesome/free-solid-svg-icons';
import useEventListener from '@/plugins/useEventListener';
import SearchModal from '@/components/dashboard/search/SearchModal';

export default () => {
    const [visible, setVisible] = useState(false);

    useEventListener('keydown', (e: KeyboardEvent) => {
        if (['input', 'textarea'].indexOf(((e.target as HTMLElement).tagName || 'input').toLowerCase()) < 0) {
            if (!visible && (e.metaKey || e.ctrlKey) && ['/', 'k'].includes(e.key.toLowerCase())) {
                e.preventDefault();
                setVisible(true);
            }
        }
    });

    return (
        <>
            {visible && <SearchModal appear visible={visible} onDismissed={() => setVisible(false)} />}
            <button type={'button'} className={'astra-search-trigger'} onClick={() => setVisible(true)}>
                <FontAwesomeIcon icon={faSearch} />
                <span className={'flex-1 text-left'}>Buscar servidor</span>
                <kbd>Ctrl K</kbd>
            </button>
        </>
    );
};

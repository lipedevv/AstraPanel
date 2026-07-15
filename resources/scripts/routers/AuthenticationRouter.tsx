import React from 'react';
import { Route, Switch, useRouteMatch } from 'react-router-dom';
import LoginContainer from '@/components/auth/LoginContainer';
import ForgotPasswordContainer from '@/components/auth/ForgotPasswordContainer';
import ResetPasswordContainer from '@/components/auth/ResetPasswordContainer';
import LoginCheckpointContainer from '@/components/auth/LoginCheckpointContainer';
import { NotFound } from '@/components/elements/ScreenBlock';
import { useHistory, useLocation } from 'react-router';

export default () => {
    const history = useHistory();
    const location = useLocation();
    const { path } = useRouteMatch();

    return (
        <div className={'relative flex min-h-screen items-center overflow-hidden py-8 sm:py-12'}>
            <div
                className={
                    'pointer-events-none absolute left-[8%] top-[5%] h-72 w-72 rounded-full bg-cyan-400/10 blur-3xl'
                }
            />
            <div
                className={
                    'pointer-events-none absolute bottom-[4%] right-[8%] h-96 w-96 rounded-full bg-purple-500/10 blur-3xl'
                }
            />
            <Switch location={location}>
                <Route path={`${path}/login`} component={LoginContainer} exact />
                <Route path={`${path}/login/checkpoint`} component={LoginCheckpointContainer} />
                <Route path={`${path}/password`} component={ForgotPasswordContainer} exact />
                <Route path={`${path}/password/reset/:token`} component={ResetPasswordContainer} />
                <Route path={`${path}/checkpoint`} />
                <Route path={'*'}>
                    <NotFound onBack={() => history.push('/auth/login')} />
                </Route>
            </Switch>
        </div>
    );
};

import React, { Component } from 'react';
import { Route } from 'react-router';
import { MainPanel } from './components/MainPanel';
import { Home } from './components/Home';
import { Navigation } from './components/Navigation';
import { Services } from './components/Services';


import './custom.css'

export default class App extends Component {
  static displayName = App.name;

  render () {
    return (
        <MainPanel>
        <Route exact path='/' component={Home} />
            <Route path='/navigation' component={Navigation} />
            <Route path='/services' component={Services} />
        </MainPanel>
    );
  }
}

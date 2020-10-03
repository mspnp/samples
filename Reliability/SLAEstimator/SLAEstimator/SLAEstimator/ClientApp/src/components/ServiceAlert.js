import React, { Component } from 'react';

export class ServiceAlert extends Component {

    constructor(props) {
        super(props);
        this.state = {};
    }

    render() {

        return (
            <div id="serviceAlert" className={this.props.className}>
                Adding Service...
            </div>
        );
    }
}

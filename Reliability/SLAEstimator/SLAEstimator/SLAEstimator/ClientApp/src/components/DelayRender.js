import React, { Component } from 'react';
import './Styles.css';
import PropTypes from 'prop-types';

export class DelayRender extends Component {

    constructor(props) {
        super(props);
        this.state = { hidden: true };
    }

    componentDidMount() {
        setTimeout(() => {
            this.setState({ hidden: false });
        }, this.props.waitBeforeShow);
    }

    render() {
        return this.state.hidden ? <p><img src="images/load.gif"></img></p> : this.props.children;
    }
}

DelayRender.propTypes = { waitBeforeShow: PropTypes.number.isRequired };

export default DelayRender;
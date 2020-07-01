import React, { Component } from 'react';
import './Styles.css';

export class SearchBar extends Component {

    constructor(props) {
        super(props);
    }

    render() {
        return (
            <div className="service-search-container">
                <input id="searchBox" className="service-search-box" placeholder="Search services" onKeyUp={ev => this.props.onTextSearchEnter(ev.currentTarget.value)}></input>
                <button id="clearSearch" className="clear-search" type="submit" onClick={ev => this.props.onClearSearch(ev)} >x</button>
            </div>
        );
    }
}

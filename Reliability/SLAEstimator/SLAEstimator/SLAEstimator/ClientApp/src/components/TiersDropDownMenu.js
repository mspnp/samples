import React, { Component } from 'react';
import './Styles.css';

export class TiersDropDownMenu extends Component {

    constructor(props) {
        super(props);
    }

    displayHideContent(evt) {
        const content = evt.currentTarget.parentElement.children[1];

        content.className = content.className === "dropdown-content" ? "dropdown-content-show" : "dropdown-content";
    }

    changeTier(ev) {
        ev.currentTarget.parentElement.parentElement.className = "dropdown-content";
        this.props.onChangeTier(ev);
    }

    deleteTier(ev) {
        this.props.onDeleteTier(ev);
    }

    addTier(ev) {
        this.props.onAddTier(ev);
    }

    render() {
        return (
            <div className="dropdown-container">
                <div className="tier-label">
                    Tier
                </div>
                <div className="dropdown">
                    <div className="dropdown-header" onClick={ev => this.displayHideContent(ev)}>
                        <div className="dropdown-header-text">{this.props.currentTier}</div>
                        <div className="dropdown-header-arrow"></div>
                    </div>
                    <div class="dropdown-content ">
                        {this.props.tiers.map(tier =>
                            <div className="dropdown-item">
                                <div className="dropdown-item-text" onClick={ev => this.changeTier(ev)}>{tier.name}</div>
                                <div className="delete-tier" id={tier.name} tooltip="Delete Tier" title="delete tier" onClick={ev => this.deleteTier(ev)}></div>
                            </div>
                        )}
                    </div>
                </div>
                <div className="new-tier">
                    <input type="text" maxLength="20" id="newTier" className="new-tier-box" />
                </div>
                <div className="add-tier">
                    <button className="add-tier" type="submit" onClick={ev => this.addTier(ev)} title="Add new tier" >+</button>
                </div>
            </div>
        );
    }
}

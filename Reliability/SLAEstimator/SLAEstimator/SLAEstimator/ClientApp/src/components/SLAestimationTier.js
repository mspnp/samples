import React, { Component } from 'react';
import { SLAestimationCategory } from './SLAestimationCategory';
import './Styles.css';

export class SLAestimationTier extends Component {

    static renderSLATierTable(tierName, categoryName, catServices, deleteEstimationCategory,
        expandCollapseEstimationCategory) {

        return (
            <div>
                <div className="div-show">
                    <SLAestimationCategory tierName={tierName} categoryName={categoryName} catServices={catServices}
                        onDeleteEstimationCategory={deleteEstimationCategory}
                        onExpandCollapseEstimationCategory={expandCollapseEstimationCategory}
                    />
                </div>
            </div>
        );
    }

    getSelectedRegionOption(tier) {
        return this.props.tiers.find(t => t.name === tier).pairedRegion;
    }


    render() {
        if (this.props.tierServices.length > 0) {

            const tierSla = this.props.calculateTierTotal(this.props.tierName);
            const downTime = this.props.calculateDownTime(tierSla);

            const categories = ["Media", "Internet of Things", "Integration", "Security", "Identity AD", "Web", "Storage", "Networking", "Compute", "Databases", "Management and Governance", "Analytics", "AI + Machine Learning", "Containers", "Blockchain"];
            var catContents = [];

            for (var i = 0; i < categories.length; i++) {
                var catServices = this.props.tierServices
                    .filter(o => o.service.categoryName === categories[i])
                    .map(svc => svc.service);

                if (catServices.length > 0) {
                    let catContent = SLAestimationTier.renderSLATierTable(this.props.tierName, categories[i], catServices,
                        this.props.onDeleteEstimationCategory, this.props.onExpandCollapseEstimationCategory);

                    catContents.push(catContent);
                }
            }

            return (
                <div>
                    <div className="tier-head ">
                        <div className="estimation-head-ec-arrow"><button className="down-arrow" onClick={ev => this.props.onExpandCollapseEstimationTier(ev)} /></div>
                        <div className="tier-head-title-left">{this.props.tierName} Tier</div>
                        <div className="tier-head-region">
                            <div className={this.props.tierName === "Global" ? "regions-option-hidden" : "region-div-left"}>Deploy to Paired Azure Regions: </div>
                            <div className="region-div-right">
                                <select className={this.props.tierName === "Global" ? "regions-option-hidden" : "tier-option"} id={this.props.tierName} value={this.getSelectedRegionOption(this.props.tierName)}  onChange={ev => this.props.onSelectRegion(ev)} >
                                    <option value="no">No</option>
                                    <option value="yes">Yes</option>
                                </select>
                            </div>
                        </div>
                        <div className="estimation-head-delete" id={this.props.tierName} onClick={ev => this.props.onDeleteEstimationTier(ev)}><img src="images/delete.png" title="Delete the Tier" /></div>
                    </div>
                    <br />
                    {catContents}
                    <div className="div-show">
                        <br />
                        <div className="estimation-totals-panel">
                            <br />
                            <div className="tier-estimation-total-label"><p>{this.props.tierName} Tier Composite SLA: {tierSla} %</p></div>
                            <div className="tier-estimation-total-label"><p>Maximum acceptable downtime in minutes /Month: {downTime} </p></div>
                        </div>
                    </div>
                </div>
            );
        }

        return (<div></div>);
    }
}

import React, { Component } from 'react';
import { SLAestimationCategory } from './SLAestimationCategory';
import './Styles.css';

export class SLAestimationTier extends Component {

    static renderSLATierTable(tierName, categoryName, catServices, deleteEstimationCategory,
        expandCollapseEstimationCategory, deleteEstimationTier, expandCollapseEstimationTier,
        calculateTierTotal, calculateDownTime) {

        const tierSla = calculateTierTotal(tierName);
        const downTime = calculateDownTime(tierSla);

        return (
            <div>
                <div className="tier-head ">
                    <div className="estimation-head-ec-arrow"><button className="down-arrow" onClick={ev => expandCollapseEstimationTier(ev)} /></div>
                    <div className="tier-head-title">{tierName} Tier</div>
                    <div className="estimation-head-delete" id={tierName} onClick={ev => deleteEstimationTier(ev)}><img src="images/delete.png" title="Delete the Tier" /></div>
                </div>
                <br/>
                <div className="div-show">
                    <SLAestimationCategory categoryName={categoryName} catServices={catServices}
                        onDeleteEstimationCategory={deleteEstimationCategory}
                        onExpandCollapseEstimationCategory={expandCollapseEstimationCategory}
                    />
                </div>
                <div className="div-show">
                    <br/>
                    <div className="estimation-totals-panel">
                    <br />
                        <div className="tier-estimation-total-label"><p>{tierName} Tier Composite SLA: {tierSla} %</p></div>
                        <div className="tier-estimation-total-label"><p>Maximum acceptable downtime in minutes /Month: {downTime} </p></div>
                    </div>
                </div>
            </div>
        );
    }

    render() {
        if (this.props.tierServices.length > 0) {

            const categories = ["Media", "Internet of Things", "Integration", "Security", "Identity AD", "Web", "Storage", "Networking", "Compute", "Databases", "Management and Governance", "Analytics"];
            var catContents = [];

            for (var i = 0; i < categories.length; i++) {
                var catServices = this.props.tierServices
                    .filter(o => o.service.categoryName === categories[i])
                    .map(svc => svc.service);

                if (catServices.length > 0) {
                    let catContent = SLAestimationTier.renderSLATierTable(this.props.tierName, categories[i], catServices,
                        this.props.onDeleteEstimationCategory, this.props.onExpandCollapseEstimationCategory,
                        this.props.onDeleteEstimationTier, this.props.onExpandCollapseEstimationTier,
                        this.props.calculateTierTotal, this.props.calculateDownTime);

                    catContents.push(catContent);
                }
            }

            return (
                <div>
                    <br />
                    {catContents}
                </div>
            );
        }

        return (<div></div>);
    }
}

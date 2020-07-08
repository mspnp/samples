import React, { Component } from 'react';
import './Styles.css';

export class SLAestimationTier extends Component {

    static renderSLATierTable(tierName, slaEstimations, deleteEstimationEntry,
        expandCollapseEstimationEntry, deleteEstimationTier, expandCollapseEstimationTier,
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
                    {slaEstimations.map(sla =>
                        <div id={sla.id}>
                            <div className="estimation-head">
                                <div className="estimation-head-ec-arrow"><button className="down-arrow" onClick={ev => expandCollapseEstimationEntry(ev)} /></div>
                                <div className="estimation-head-title">{sla.service.categoryName} Category</div>
                                <div className="estimation-head-delete" onClick={ev => deleteEstimationEntry(ev)}><img src="images/delete.png" title="Delete the service" /></div>
                            </div>
                            <br />
                            <div className="estimation-layout">
                                <div className="estimation-service">
                                    <div className="estimation-service-icon"><img src={"images/" + sla.service.imageFile}></img></div>
                                    <div className="estimation-service-name"><p>{sla.service.name}</p></div>
                                    <div className="estimation-sla"><p>SLA: {sla.service.sla} %</p></div>
                                </div>
                            </div>
                        </div>
                    )}
                </div>
                <div className="div-show">
                    <br/>
                    <div className="estimation-totals-panel">
                    <br />
                        <div className="tier-estimation-total-label"><p>{tierName} Tier Composite SLA: {tierSla} %</p></div>
                    <div className="tier-estimation-total-label"><p>Projected Max Minutes of Downtime/Month: {downTime} </p></div>
                    </div>
                </div>
            </div>
        );
    }

    render() {
        if (this.props.services.length > 0) {
            let contents = SLAestimationTier.renderSLATierTable(this.props.tierName, this.props.services,
                this.props.onDeleteEstimationEntry, this.props.onExpandCollapseEstimationEntry,
                this.props.onDeleteEstimationTier, this.props.onExpandCollapseEstimationTier,
                this.props.calculateTierTotal, this.props.calculateDownTime);

            return (
                <div>
                    <br />
                    {contents}
                </div>
            );
        }

        return (<div></div>);
    }
}

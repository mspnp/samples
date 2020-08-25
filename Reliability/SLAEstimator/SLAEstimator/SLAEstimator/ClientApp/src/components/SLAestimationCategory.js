import React, { Component } from 'react';
import './Styles.css';

export class SLAestimationCategory extends Component {

    static renderSLACategoryTable(tierName, categoryName, catServices, deleteEstimationCategory, deleteEstimationService, expandCollapseEstimationCategory)
    {
        return (
            <div id={tierName}>
                <div className="estimation-head" id={categoryName}>
                    <div className="estimation-head-ec-arrow"><button className="down-arrow" onClick={ev => expandCollapseEstimationCategory(ev)} /></div>
                    <div className="estimation-head-title">{categoryName} Category</div>
                    <div className="estimation-head-delete" onClick={ev => deleteEstimationCategory(ev)}><img src="images/delete.png" title="Delete the service category" /></div>
                </div>
                <br />
                <div className="div-show">
                    {catServices.map(svc =>
                        <div id={svc.id}>
                            <div className="estimation-spacer">
                            </div>
                            <div className="estimation-head" id={svc.name}>
                                <div className="estimation-head-ec-arrow"></div>
                                <div className="estimation-head-title"></div>
                                <div className="estimation-head-delete" onClick={ev => deleteEstimationService(ev)}><img src="images/delete.png" title="Delete the service" /></div>
                            </div>
                            <div className="estimation-layout">
                                <div className="estimation-service">
                                    <div className="estimation-service-icon"><img src={"images/" + svc.imageFile}></img></div>
                                    <div className="estimation-service-name"><p>{svc.name}</p></div>
                                    <div className="estimation-sla"><p>SLA: {svc.sla} %</p></div>
                                </div>
                            </div>
                        </div>
                    )}
                </div>
            </div>
        );
    }

    render() {
        if (this.props.catServices.length > 0) {
            let contents = SLAestimationCategory.renderSLACategoryTable(this.props.tierName, this.props.categoryName, this.props.catServices,
                this.props.onDeleteEstimationCategory, this.props.onDeleteEstimationService , this.props.onExpandCollapseEstimationCategory);

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
